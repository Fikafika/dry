describe Dynamic::Schema::Association::Base, elasticsearch: false, sidekiq: false do

  describe :AssociationUpdateDefaultLayouts do

    describe '.create' do

      context 'two successively' do
        before(:each) do
          @schema = Dynamic::Schema.find_by(name: "UneekTest2")
          @schema.destroy if @schema.present?
          @schema = Dynamic::Schema.create!({
            name: 'UneekTest2',
          })

          @Contact = @schema.klasses.create!(name: 'Contact')
          @Email = @schema.klasses.create!(name: 'Email')
          @Phone = @schema.klasses.create!(name: 'Phone')

          @layout_edit_contact = @schema.layouts.with_action(:edit).where(
            klass_name: @Contact.const_absolute_name,
            updated_when_schema_is_changed: true,
            default: true,
          ).last

          expect(@layout_edit_contact).to_not be_nil

          @sheet_all_tab = @layout_edit_contact.elements.detect do |e|
            e.component == 'Crm::Sheet::TabBar::Tab' && e.component_params['name'] == 'all'
          end

          expect(@sheet_all_tab).to_not be_nil
        end

        it 'should update_sheet_all_tab with all has_many associations' do
          expect{
            @Contact.associations.create!(name: 'asso1', target_klass: @Email, type: 'HasMany')
            @Contact.associations.create!(name: 'asso2', target_klass: @Phone, type: 'HasMany')
          }.to change{
            @infinite_scroller = @sheet_all_tab.descendants.detect{|e| e.component == 'InfiniteScroller'}
          }

          expect(
            @infinite_scroller.component_params_converter_options['schema_association_ids'].length
          ).to eq 2
        end

      end
    end

  end

  describe '.update' do

    context 'name changed' do
      it 'should change autocomplete filters columns' do
        @schema = Dynamic::Schema.create!(name: 'my')
        @klass = @schema.klasses.create(name: 'Klass')
        @assoc = @klass.associations.create(name: 'assoc', target_klass: @klass, type: 'BelongsTo')
        @klass.associations.create(name: 'associated', target_klass: @klass, type: 'BelongsTo')

        form = @schema.forms.where(klass_name: @klass.const_absolute_name).first
        element = form.elements.detect{|e| e.attribute_name == 'associated'}
        element.update(autocomplete_filters: {assoc: {contains_id: '1'}})

        expect{
          @assoc.update(name: 'assoc2')
        }.to change {
          element.class.find(element.id).autocomplete_filters
        }.from({'assoc' => {'contains_id' => '1'}}).to({'assoc2' => {'contains_id' => '1'}})
      end

      xit 'should change autocomplete filters variables' # TODO
    end

  end

  describe 'default elasticsearch order' do
    before(:each) do
      @schema = Dynamic::Schema.find_by(name: 'my')
      @schema.destroy if @schema.present?
      @schema = Dynamic::Schema.create!(name: 'my')
      @Contact = @schema.klasses.create!(name: 'Contact', attrs_attributes: [{name: 'name', type: 'String'}])
      @Account = @schema.klasses.create!(name: 'Account', attrs_attributes: [{name: 'name', type: 'String'}])
      @Account.associations.create!(
        name: 'contacts',
        target_klass: @Contact,
        type: 'HasMany',
        default_elasticsearch_order: [['name', 'asc']],
      )
      @schema.load
    end

    it 'should be provided in reflection' do
      expect(D::My::Account.reflect_on_association(:contacts).default_elasticsearch_order).to eq([['name', 'asc']])
    end
  end

  describe '.human_name' do
    it "should not change human_name if human_name_en and human_name_fr didn't change" do
      schema = Dynamic::Schema.create!(name: 'UneekTest3')
      klass = schema.klasses.create!(name: 'Klass')
      a = klass.associations.create!(human_name_en: 'A', human_name_fr: '', type: 'HasMany')
      a.assign_attributes(human_name_en: 'A', human_name_fr: '')
      expect(a.human_name_changed?).to eq false
    end
  end

  describe 'inverse_of', elasticsearch: true, sidekiq: true do
    context 'create inverse of another association with existing records' do
      before(:each) do
        @schema = Dynamic::Schema.create!(name: 'My')
        @Contact = @schema.klasses.create!(human_name: 'Contact')
        @Email = @schema.klasses.create!(human_name: 'Email', attrs_attributes: [{name: 'address', type: 'String'}])
        @email_owner = @Email.associations.create!(name: 'owner', type: 'BelongsTo', touch_target: true)
        @Contact.update(options_for_indexed_json: {include: {emails: {only: ['address']}}})
        @schema.load
        @contact = D::My::Contact.create!
        @email = D::My::Email.create!(address: 'a@a.fr', owner: @contact)
      end

      it 'should compute inverse associations of records' do
        Dynamic::Elasticsearch.wait_for_complete do
          expect{
            @Contact.associations.create!(name: 'emails', target_klass: @Email, type: 'HasMany', inverse_of: @email_owner, update_associations_from_inverses: true)
          }.to change {
            D::My::DynamicAssociation.count
          }.by(1)
        end
        @schema.unload
        @schema.load
        @contact = D::My::Contact.find(@contact.id)
        @email = D::My::Email.find(@email.id)
        expect(@contact.emails.to_a).to eq([@email])
        expect(@contact.__opensearch__.source['emails']).to be_present
      end
    end
  end

  describe 'default elasticsearch filters' do
    before(:each) do
      @schema = Dynamic::Schema.find_by(name: 'my')
      @schema.destroy if @schema.present?
      @schema = Dynamic::Schema.create!(name: 'my')
      @Contact = @schema.klasses.create!(name: 'Contact', attrs_attributes: [
        {name: 'first_name', type: 'String'},
        {name: 'last_name', type: 'String'},
        {name: 'civility', type: 'String'}
      ])
      @Account = @schema.klasses.create!(name: 'Account', attrs_attributes: [{name: 'name', type: 'String'}])
      @assoc = @Account.associations.create!(name: 'contacts', target_klass: @Contact, type: 'HasMany')
    end

    it 'should be provided in reflection' do
      @assoc.update!(default_elasticsearch_filters: {'civility' => {'equal' => 'Mr'}})
      @schema.load
      reflection = D::My::Account.reflect_on_association(:contacts)
      expect(reflection).to respond_to(:default_elasticsearch_filters)
      expect(reflection.default_elasticsearch_filters).to eq({'civility' => {'equal' => 'Mr'}})
    end

    it 'should allow to remove variables' do
      @assoc.update!(default_elasticsearch_filters: {
        'civility' => {'equal' => 'Mr'},
        'first_name' => {'equal' => {'variable' => 'last_name'}},
      })
      @schema.load
      reflection = D::My::Account.reflect_on_association(:contacts)
      expect(reflection.default_elasticsearch_filters(remove_variables: true)).to eq({
        'civility' => {'equal' => 'Mr'},
      })
    end

    it 'should allow to remove variables even if filters contains an "or"' do
      @assoc.update!(default_elasticsearch_filters: {
        'or' => [
          {'civility' => {'equal' => 'Mr'}},
          {'first_name' => {'equal' => {'variable' => 'last_name'}}},
        ],
        'first_name' => {'equal' => 'A'},
      })
      # for instance, this filter can return Mrs A A
      # the variable can't just be removed because Mrs B B would not be returned with these filters:
      #  {
      #    'civility' => {'equal' => 'Mr'}, # and
      #    'first_name' => {'equal' => 'A'},
      #  },

      @schema.load
      reflection = D::My::Account.reflect_on_association(:contacts)
      expect(reflection.default_elasticsearch_filters(remove_variables: true)).to eq({
        'first_name' => {'equal' => 'A'},
      })
    end

  end

end
