describe Dynamic::Record::SubmitAllWorker do
  before(:each) do
    @schema = Dynamic::Schema.create!(name: 'my')
    @user = User.create!(last_name: 'albert', email: 'albert@mousquetaire.fr', login: 'albert@mousquetaire.fr')

    @contact = @schema.klasses.create!(name: 'Contact', attrs_attributes: [{name: 'name', type: 'String'}])
    @phone = @schema.klasses.create!(name: 'Phone', attrs_attributes: [{name: 'number', type: 'String'}, {name: 'label', type: 'String'}])
    @sms = @schema.klasses.create!(name: 'Sms', attrs_attributes: [{name: 'message', type: 'String'}, {name: 'number', type: 'String'}])

    @phone_owner_assoc = @phone.associations.create!(owner_klass: @phone, target_klass: @contact, name: 'owner', type: 'BelongsTo')
    @sms_owner_assoc = @sms.associations.create!(owner_klass: @sms, target_klass: @contact, name: 'owners', type: 'HasMany')
    @sms_phone_assoc = @sms.associations.create!(owner_klass: @sms, target_klass: @phone, name: 'phone', type: 'BelongsTo')

    @contact.associations.create!([
      {name: 'smses', type: 'HasMany', target_klass: @sms, inverse_of: @sms_owner_assoc},
      {name: 'phones', type: 'HasMany', target_klass: @phone},
    ])
    @phone.associations.create!(name: 'smses', type: 'HasMany', target_klass: @sms, inverse_of: @sms_phone_assoc)

    @schema.load
  end

  context 'where_filters' do
    before(:each) do
      @form = @schema.forms.create!(
        klass_name: @sms.const_absolute_name,
        target_klass_name: @contact.const_absolute_name,
        association_klass_name: @contact.const_absolute_name,
        association_name: 'smses',
        actions: [:submit_all],
        elements_attributes: [
          { root_klass_name: @sms.const_absolute_name, attribute_name: 'message', type: 'Attribute::String' },
        ]
      )
      Dynamic::Elasticsearch.wait_for_complete(timeout: 20) do
        @a1 = D::My::Contact.create!(name: 'A 1', phones_attributes: [{number: '0612345678'}, {number: '0712345678'}])
        @a2 = D::My::Contact.create!(name: 'A 2', phones_attributes: [{number: '0712345678'}, {number: '0612345678'}])
        @b = D::My::Contact.create!(name: 'B', phones_attributes: [{number: '0212345678'}])
      end
      @perform_params = {
        user_id: @user.id,
        klass_name: @contact.const_absolute_name,
        form_id: @form.id,
        form_params: {'sms@0' => {message: 'bonjour'}},
        params: {
          scopes: {'0' => {name: 'where_filters', args: {'0' => {name: {contains: 'A'}}}}},
        }
      }.deep_stringify_keys
    end

    it 'should update all with a new associated record' do
      expect {
        Dynamic::Record::SubmitAllWorker.wait_for_complete do
          Dynamic::Record::SubmitAllWorker.perform_async(@perform_params)
        end
      }.to change {
        @a1.reload.smses.count
      }.by(1).and change {
        @a2.reload.smses.first&.message
      }.from(nil).to('bonjour')
    end

    it 'should create as many smses as filtered contacts' do
      expect {
        Dynamic::Record::SubmitAllWorker.wait_for_complete do
          Dynamic::Record::SubmitAllWorker.perform_async(@perform_params)
        end
      }.to change {
        D::My::Sms.count
      }.by(2)
    end
  end

  context 'no filters' do
    before(:each) do
      @form = @schema.forms.create!(
        klass_name: @sms.const_absolute_name,
        source_klass_name: @sms.const_absolute_name,
        target_klass_name: @contact.const_absolute_name,
        association_klass_name: @contact.const_absolute_name,
        association_name: 'smses',
        actions: [:submit_all],
        elements_attributes: [
          { root_klass_name: @sms.const_absolute_name, attribute_name: 'message', type: 'Attribute::String' },
        ]
      )
      @a1 = D::My::Contact.create!(name: 'A 1', phones_attributes: [{number: '0612345678'}, {number: '0712345678'}])
      @a2 = D::My::Contact.create!(name: 'A 2', phones_attributes: [{number: '0712345678'}, {number: '0612345678'}])
      @b = D::My::Contact.create!(name: 'B', phones_attributes: [{number: '0212345678'}])
      @perform_params = {
        klass_name: 'D::My::Contact',
        user_id: @user.id,
        form_id: @form.id,
        form_params: {'sms@0' => {message: 'bonjour'}},
      }.deep_stringify_keys
    end

    it 'should update notification progress' do
      notification = D::My::R::Notification.create!
      @perform_params.merge!('notification' => notification)
      expect {
        Dynamic::Record::SubmitAllWorker.new.perform(@perform_params)
        notification.reload
      }.to change {
        notification.total
      }.to(3).and change {
        notification.current
      }.to(3).and change {
        notification.state
      }.to('finished')
    end

    it 'should do nothing if no user provided' do
      @perform_params.delete('user_id')
      expect {
        Dynamic::Record::SubmitAllWorker.new.perform(@perform_params)
      }.to_not change {
        D::My::Sms.count
      }
    end

    context 'default_value_formula' do
      before(:each) do
        @form.elements.create!(
          root_klass_name: @sms.const_absolute_name,
          attribute_name: 'phone',
          type: 'Association::BelongsTo',
          default_value_formula: 'nth(phones, 0)',
          record_type_for_default_value_formula: :target_record,
        )
      end

      it 'should assign different phones for each sms' do
        Dynamic::Record::SubmitAllWorker.new.perform(@perform_params)
        expect(D::My::Sms.first.phone).to eq(@a1.reload.phones.first)
        expect(D::My::Sms.last.phone).to eq(@b.reload.phones.first)
      end

    end

    context 'on_conflict' do
      before(:each) do
        @a2.phones.first.update!(number: @a1.phones.first.number)
        @form.elements.create!(
          root_klass_name: @sms.const_absolute_name,
          attribute_name: 'number',
          type: 'Attribute::String',
          default_value_formula: 'nth(phones.number, 0)',
          record_type_for_default_value_formula: :target_record,
        )
        @perform_params['on_conflict_element_id'] = @form.elements.detect {|e| e.attribute_name == 'number'}.id
        @perform_params['form_params']['batch_id'] = '1'
      end

      it 'should create unique record based on_conflict param value' do
        expect {
          Dynamic::Record::SubmitAllWorker.new.perform(@perform_params)
        }.to change {
          D::My::Sms.count
        }.by(2)
      end

      it 'should associate the same record to multiple associations' do
        Dynamic::Record::SubmitAllWorker.new.perform(@perform_params)
        @a1.reload
        @a2.reload
        expect(@a1.smses).to_not be_empty
        expect(@a2.smses).to_not be_empty
        expect(@a1.sms_ids).to eq(@a2.sms_ids)
      end

      it 'should not remove previous associations' do
        old_sms = @a1.phones.first.smses.create!(owners: [@a1], number: '0612345678', message: 'Hello')
        Dynamic::Record::SubmitAllWorker.new.perform(@perform_params)
        @a1.reload
        expect(@a1.smses.count).to eq(2)
        expect(@a1.sms_ids).to include(old_sms.id)
      end

      context 'on belongs_to input' do
        before(:each) do
          @form.elements.detect {|e| e.attribute_name == 'number'}.destroy!
          @form.elements.create!(
            root_klass_name: @sms.const_absolute_name,
            attribute_name: 'phone',
            type: 'Association::BelongsTo',
            default_value_formula: 'nth(phones, 0)',
            record_type_for_default_value_formula: :target_record,
          )
          @a1.update!(phones: @a2.phones)
          @perform_params['on_conflict_element_id'] = @form.elements.detect {|e| e.attribute_name == 'phone'}.id
        end

        it 'should create unique record based on_conflict param value' do
          expect {
            Dynamic::Record::SubmitAllWorker.new.perform(@perform_params)
          }.to change {
            D::My::Sms.count
          }.by(2)
        end

        it 'should associate record' do
          Dynamic::Record::SubmitAllWorker.new.perform(@perform_params)
          @a1.reload
          @a2.reload
          expect(@a1.phones.map(&:smses)).to_not be_empty
          expect(@a2.phones.map(&:smses)).to_not be_empty
          expect(@a1.phones.map(&:smses)).to eq(@a2.phones.map(&:smses))
        end
      end

      context 'with HasMany element having a default_value_formula' do
        before(:each) do
          @sms_phone_assoc.update!(type: 'HasMany', name: 'phones')
          @schema.load
          @form.elements.create!(
            root_klass_name: @sms.const_absolute_name,
            attribute_name: 'phones',
            type: 'Association::HasMany',
            default_value_formula: 'nth(phones, 0)',
            record_type_for_default_value_formula: :target_record,
          )
        end

        it 'should fill duplicate record has_many association with target_record' do
          expect {
            Dynamic::Record::SubmitAllWorker.new.perform(@perform_params)
          }.to change {
            D::My::Sms.first&.phones&.count
          }.from(nil).to(2)
        end
      end

      context 'nested attributes' do
        before(:each) do
          @form = @schema.forms.create!({
            klass_name: @sms.const_absolute_name,
            target_klass_name: @contact.const_absolute_name,
            association_klass_name: @contact.const_absolute_name,
            association_name: 'smses',
            actions: [:submit_all],
            elements_attributes: [
              {
                root_klass_name: @sms.const_absolute_name,
                attribute_name: 'message',
                type: 'Attribute::String'
              },
              {
                root_klass_name: @sms.const_absolute_name,
                method_names: ['phone'],
                attribute_name: 'number',
                type: 'Attribute::String',
                default_value_formula: 'nth(phones.number, 0)',
                record_type_for_default_value_formula: :target_record,
                editor: :hidden,
              },
            ]
          })
          @perform_params = {
            user_id: @user.id,
            klass_name: @contact.const_absolute_name,
            form_id: @form.id,
            form_params: {'sms@0' => {message: 'bonjour'}, batch_id: '1'},
            on_conflict_element_id: @form.elements.detect {|e| e.attribute_name == 'label'}.id
          }.deep_stringify_keys
        end

        xit 'should create unique record based on_conflict param value' do
          expect {
            Dynamic::Record::SubmitAllWorker.new.perform(@perform_params)
          }.to change {
            D::My::Sms.count
          }.by(2)
        end
      end
    end

  end

end
