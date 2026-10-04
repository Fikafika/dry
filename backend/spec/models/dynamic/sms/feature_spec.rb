describe Dynamic::Sms::Feature, elasticsearch: false, sidekiq: false do
  before(:each) do
    @schema = Dynamic::Schema.create!(name: 'my')
    @phone_klass = @schema.klasses.create!(
      name: 'Phone',
      attrs_attributes: [
        name: 'number', type: 'String'
      ]
    )
    @feature = @schema.features.find_by(name: 'Dynamic::Sms::Feature')
  end

  describe '.after_enabled' do

    context 'with Phone klass missing' do

      it 'should raise an error' do
        expect{@feature.update!(enabled: true)}.to raise_error {ActiveRecord::RecordInvalid}
      end

    end # end of context with Phone klass missing

    context 'with Phone klass present' do
      before(:each) do
        @feature.options.detect {|o| o.name == 'phone_klass'}.update!(value: @phone_klass.id)
      end

      it 'should create associations has_many and belongs_to for Sms and History' do
        expect{
          @feature.update!(enabled: true)
        }.to change{
          sms = @schema.klasses.find_by(name: 'Sms')
          if sms
            history = @schema.klasses.find_by(name: 'SmsHistory')
            belongs_to = sms.associations.first
            has_many = history.associations.first
            belongs_to.target_klass_id == has_many.owner_klass_id
          end
        }.from(nil).to(true)
      end

      it 'should create associations has_many for Phone and Sms' do
        expect{
          @feature.update!(enabled: true)
        }.to change{
          sms = @schema.klasses.find_by(name: 'Sms')
          if sms
            has_many_phones = sms.associations.find_by(name: 'phones')
            has_many_smses = @phone_klass.reload.associations.first
            has_many_phones.target_klass_id == has_many_smses.owner_klass_id
          end
        }.from(nil).to(true)
      end

      context 'and the klass Sms and History already exist' do
        before(:each) do
          @feature.update!(enabled: true)
          @feature.update!(enabled: false)
        end

        it 'should not create new klasses' do
          expect{
            @feature.update!(enabled: true)
          }.to_not change{
            @schema.klasses.count
          }
        end

        it 'should not create new forms' do
          expect{
            @feature.update!(enabled: true)
          }.to_not change{
            @schema.forms.count
          }
        end

      end # end of context 'and the klass Sms and History already exist'

      context 'Forms' do

        it 'should use smsarea for message input' do
          expect{
            @feature.update!(enabled: true)
          }.to change{
            Dynamic::Form::Element::Attribute::Text.where(attribute_name: 'message', klass_name: 'D::My::Sms', editor: :smsarea).count
          }.by(3)
        end

        it 'should create a new form throught Phone sheet' do
          expect{
            @feature.update!(enabled: true)
          }.to change{
            Dynamic::Form.where(klass_name: 'D::My::Sms', association_klass_name: 'D::My::Phone', association_name: 'smses').count
          }.by(1)
        end

        it 'should not create a new form for history "new"' do
          expect{
            @feature.update!(enabled: true)
          }.to_not change{
            Dynamic::Form.where(klass_name: 'D::My::SmsHistory', actions: [1]).count
          }
        end

        it 'should create a new form for history "edit"' do
          expect{
            @feature.update!(enabled: true)
          }.to change{
            Dynamic::Form.where(klass_name: 'D::My::SmsHistory', actions: [2]).count
          }.by(1)
        end

        it 'should create disabled elements for sms "edit"' do
          @feature.update!(enabled: true)
          @form = Dynamic::Form.find_by(klass_name: 'D::My::Sms', actions: [2])
          expect(@form.elements.map(&:disabled)).to all(eq(true))
        end

        it 'should create a new form for history "show"' do
          expect{
            @feature.update!(enabled: true)
          }.to change{
            Dynamic::Form.where(klass_name: 'D::My::SmsHistory', actions: [4]).count
          }.by(1)
        end

        context 'Submission' do
          before(:each) do
            User.current = User.create!(login: 'abc@d.com', email: 'abc@d.com')
            @contact_klass = @schema.klasses.create!(name: 'Contact', attrs_attributes: [{name: 'name', type: 'String'}])
            owner_assoc = @phone_klass.associations.create!(name: 'owner', type: 'BelongsTo')
            @contact_klass.associations.create!(name: 'phones', type: 'HasMany', target_klass: @phone_klass, inverse_of: owner_assoc)
            @feature.options.detect {|o| o.name == 'phone_number_formula'}.update!(value: 'number')
            @feature.options.detect {|o| o.name == 'owner_formula'}.update!(value: 'owner')
            @owner_concern = @feature.concerns.create!(
              name: "Owner",
              klass: @contact_klass,
              options_attributes: [
                {
                  name: 'default_sender',
                  human_name_fr: 'Expéditeur par défaut',
                  human_name_en: 'Default sender',
                  type: 'String',
                  value: 'toto'
                },
                {
                  name: 'phone_formula',
                  human_name_fr: "Formule des téléphones pour l'envoi multiple",
                  human_name_en: 'Phones formula for multiple sending',
                  type: 'String',
                  value: 'nth(phones;0)'
                },
                {
                  name: 'phone_number_formula',
                  human_name_fr: "Formule des numéros de téléphones pour l'envoi multiple",
                  human_name_en: "Phones' number formula for multiple sending",
                  type: 'String',
                  value: 'nth(phones.number;0)'
                },
                {
                  name: 'owner_formula',
                  human_name_fr: "Formule des propriétaires pour l'envoi multiple",
                  human_name_en: "Phone's owner formula for multiple sending",
                  type: 'String',
                  value: 'nth(phones.owner;0)'
                },
              ]
            )
            @feature.update!(enabled: true)
            @schema.load

            @base_url = "#{ENV['SMS_API_PROTOCOL']}://#{ENV['SMS_API_HOST']}#{":#{ENV['SMS_API_PORT']}" if ENV['SMS_API_PORT']}"
            stub_request(:post, "#{@base_url}/smses").to_return(
              body: {
                state: 'created',
                sender: 'tata',
                message: 'bonjour',
              }.to_json,
              status: 200
            )

            @contact = D::My::Contact.create!(name: 'toto')
            @phone = D::My::Phone.create!(number: '+33612345678', owner: @contact)
          end

          context 'sms through phone' do
            before(:each) do
              @form = Dynamic::Form.find_by(klass_name: 'D::My::Sms', association_klass_name: 'D::My::Phone', association_name: 'smses')
              @form.target_record = @phone
            end

            it 'should copy phone attirbutes to sms' do
              @form.submit(
                {
                'sms@0' => {sender: 'tata', message: 'bonjour'}
                }.with_indifferent_access
              )
              expect(D::My::Sms.first).to have_attributes(
                owner_ids: [{id: @contact.id, type: @contact.class.name}],
                phone_ids: [@phone.id],
                phone_number: @phone.number
              )
            end
          end

          context 'sms through contact' do
            before(:each) do
              @form = Dynamic::Form.find_by(klass_name: 'D::My::Sms', association_klass_name: 'D::My::Contact', association_name: 'smses')
              @form.target_record = @contact
            end

            it 'should copy contact attirbutes to sms' do
              @form.submit(
                {
                  'sms@0' => {sender: 'tata', message: 'bonjour'},
                  'sms.phones@0' => {id: @contact.phones.first.id}
                }.with_indifferent_access
              )
              expect(D::My::Sms.first).to have_attributes(
                owner_ids: [{id: @contact.id, type: @contact.class.name}],
                phone_ids: [@phone.id],
                phone_number: @phone.number
              )
            end
          end

          xcontext 'submit_all', elasticsearch: true, sidekiq: true do # Won't work unless we stub_request for sidekiq
            before(:each) do
              Dynamic::Elasticsearch.wait_for_complete(timeout: 20) do
                @toto = D::My::Contact.create!(first_name: 'toto', phones_attributes: [{number: '+33612345678'}])
                @titi = D::My::Contact.create!(first_name: 'titi', phones_attributes: [{number: '+33765432109'}])
              end

              @form = Dynamic::Form.with_actions(Dynamic::Form::ACTIONS_TO_I[:submit_all]).last

              @notif = D::My::R::Notification.create!(
                user_id: @user.id,
                klass_name: "Bulk::SubmitAll",
                total: 2,
                data: {klass_name: @contact_klass.const_absolute_name, form_name: 'test'},
                can_cancel: true,
              )

              @perform_params = {
                user_id: @user.id,
                klass_name: @contact_klass.const_absolute_name,
                form_id: @form.id,
                form_params: {'sms@0' => {sender: 'tata', message: 'bonjour'}},
                params: {
                  scopes: {'0' => {name: 'where_filters', args: {'0' => {first_name: {contains: 't'}}}}},
                },
                notification: @notif
              }.deep_stringify_keys
            end

            it 'should create smses' do
              expect {
                Dynamic::Record::SubmitAllWorker.wait_for_complete do
                  Dynamic::Record::SubmitAllWorker.perform_async(@perform_params)
                end
              }.to change {
                D::My::Sms.count
              }.by(2)
            end
          end

        end

      end

      context 'Validations' do
        before(:each) do
          @feature.update!(enabled: true)
        end

        it 'should not create sms when sender has more than 15 digits' do
          expect(
            D::My::Sms.create(sender: '1234567890123456', message: 'oui', state: 'created', phone_number: '+33612345678').errors.count
          ).to eq(1)
        end

        it 'should not create sms when sender has more than 12 characters' do
          expect(
            D::My::Sms.create(sender: 'abcdefghijklm', message: 'oui', state: 'created', phone_number: '+33612345678').errors.count
          ).to eq(1)
        end

        it 'should not create sms when sender has unicode characters' do
          expect(
            D::My::Sms.create(sender: 'Le Père Noël', message: 'oui', state: 'created', phone_number: '+33612345678').errors.count
          ).to eq(1)
        end

        it 'should not create sms when sender is blank or nil' do
          expect{
            D::My::Sms.create(sender: '', message: 'oui', state: 'created', phone_number: '+33612345678')
            D::My::Sms.create(message: 'oui', state: 'created', phone_number: '+33612345678')
          }.to_not change{
            D::My::Sms.count
          }
        end

      end # end of context Validations

      context 'Layouts' do

        it 'should create default layouts for Sms' do
          expect{
            @feature.update!(enabled: true)
          }.to change{
            Dynamic::Layout.where(klass_name: 'D::My::Sms').count
          }.by(4)
        end

      end

      context 'and an owner concern' do
        before(:each) do
          @contact_klass = @schema.klasses.create!(name: 'Contact')
          @feature.options.detect {|o| o.name == 'phone_klass'}.update!(value: @phone_klass.id)
          @feature.concerns.create!(
            name: "Owner",
            klass: @contact_klass,
            options_attributes: [
              {
                name: 'default_sender',
                human_name_fr: 'Expéditeur par défaut',
                human_name_en: 'Default sender',
                type: 'String',
                value: 'toto'
              },
              {
                name: 'phone_formula',
                human_name_fr: "Formule des téléphones pour l'envoi multiple",
                human_name_en: 'Phones formula for multiple sending',
                type: 'String',
                value: nil
              },
              {
                name: 'phone_number_formula',
                human_name_fr: "Formule des numéros de téléphones pour l'envoi multiple",
                human_name_en: "Phones' number formula for multiple sending",
                type: 'String',
                value: nil
              },
            ]
          )
        end

        it 'should create an association with Sms on Contact' do
          expect{
            @feature.update!(enabled: true)
          }.to change{
            @contact_klass.reload.associations.detect {|a| a.name == 'smses'}.present?
          }.from(false).to(true)
        end

        it 'should add a new sms form throught Contact with default sender' do
          @feature.update!(enabled: true)
          @sms = @schema.klasses.find_by(name: 'Sms')
          @sms_forms = @schema.forms.where(klass_name: @sms.const_absolute_name, actions: [1])
          expect(@sms_forms.count).to eq(3)
          expect(@sms_forms.last.elements.detect {|e| e.attribute_name == 'sender'}.default_value).to eq('toto')
        end

        it 'should create a new form throught Contact sheet' do
          expect{
            @feature.update!(enabled: true)
          }.to change{
            Dynamic::Form.where(klass_name: 'D::My::Sms', association_klass_name: 'D::My::Contact', association_name: 'smses').count
          }.by(2)
        end

        it 'should create a new form for multiple sending' do
          expect{
            @feature.update!(enabled: true)
          }.to change{
            Dynamic::Form.with_action(:submit_all).where(target_klass_name: @contact_klass.const_absolute_name).count
          }.by(1)
        end

      end

    end # end of context with Phone klass present

  end # end of context when enabled

end
