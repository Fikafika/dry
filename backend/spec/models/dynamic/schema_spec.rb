describe Dynamic::Schema, elasticsearch: false, sidekiq: false do

  context 'multi-thread' do
    before(:each) do
      @schema = Dynamic::Schema.create!(name: 'my')
      @Contact = @schema.klasses.create!(name: 'Contact')
      @Contact.attrs.create!(name: 'civility', type: 'Enum', values_attributes: [{name: 'Mister'}, {name: 'Misses'}])
    end

    it 'should not create enum twice' do
      expect{
        [
          Thread.new do
            @schema.load
          end.run,
          Thread.new do
            @schema.load
          end.run
        ].each(&:join)
      }.to_not raise_error
    end

  end

  describe '.update' do
    before(:each) do
      @schema = Dynamic::Schema.create!(name: 'my')
    end

    context 'with klasses_attributes' do
      before(:each) do
        @Contact = @schema.klasses.create!(name: 'Contact')
      end

      it 'should not change forms count' do
        expect{
          @schema.update(@schema.as_deep_json(include: {klasses: {}, forms: {}}))
        }.to_not change {
          @schema.forms.count
        }
      end
    end

    context 'from json' do
      before(:each) do
        @json = JSON.parse(File.read(File.expand_path('../../../assets/uneek/schema.json', __FILE__))).except('id')
      end

      it 'should assign target klass even when it is declared later in file' do
        @Address_id = @json['klasses_attributes'].detect{|k| k['human_name_en'] == 'Address'}['id']
        expect {
          @schema.update!(@json)
        }.to change {
          @schema.klasses.detect{|k| k.name == 'Contact'}&.associations&.detect{|a| a.name == 'addresses'}&.target_klass&.id
        }.from(nil).to(@Address_id)
      end

      it 'should assign human name of klasses' do
        @schema.update!(@json)
        @json['klasses_attributes'].each do |k_attrs|
          I18n.available_locales.each do |locale|
            expect(
              @schema.klasses.detect{|k| k.id == k_attrs['id']}.translations.detect{|t| t.locale == locale }.human_name
            ).to eq k_attrs["human_name_#{locale}"]
          end
        end
      end

    end

    context 'from json with a form' do
      before(:each) do
        @Contact = @schema.klasses.create!(
          id: '01985a6d-6318-7e76-ab82-5a4b759066a6',
          name: 'Contact',
          attrs_attributes: [
            {
              id: '01985590-5c88-7ca4-bc77-1fb2cf27be7d',
              name: 'last_name',
              type: 'String',
            },
            {
              name: 'first_name',
              type: 'String',
            },
          ],
          associations_attributes: [
            { name: 'friends', target_klass_id: '01985a6d-6318-7e76-ab82-5a4b759066a6', type: 'HasMany'}
          ],
          validations_attributes: [{ # add a validation in order to make mandatory the form element
            name: 'mandatory attr',
            type: 'Presence',
            attr_id: '01985590-5c88-7ca4-bc77-1fb2cf27be7d',
          }]
        )

        @form = @schema.forms.with_action(:new).where(association_name: nil).first
        expect(@form.mandatory_validation_rules).to_not be_empty

        @schema.load

        D::My::Contact.create!(
          id: '01985a6f-4778-73b1-afd1-f432e6d166a2',
          last_name: 'A',
          first_name: 'a',
        )

        @form.elements.create(
          root_klass_name: 'D::My::Contact',
          attribute_name: 'friends',
          type: 'Association::HasMany',
          default_value_associations_attributes: [
            {
              record_id: '01985a6f-4778-73b1-afd1-f432e6d166a2',
              record_type: 'D::My::Contact',
            },
          ]
        )

        @json = @schema.as_deep_json(include: Dynamic::Schema.includes_for_export(forms: true), secure: false)

        expect(@json['forms_attributes']).to_not be_empty

        expect(@json['records_for_forms_attributes']).to_not be_empty

        @schema.unload

        clean

        @schema = nil
      end

      it 'should load schema, create forms and create records for forms' do
        expect {
          @schema = Dynamic::Schema.create!(@json)
        }.to_not raise_exception

        expect(@schema.forms.with_action(:new).where(association_name: nil).count).to eq 1

        @schema.load

        expect(D::My::Contact.find_by(id: '01985a6f-4778-73b1-afd1-f432e6d166a2')).to be_present

        @form = @schema.forms.with_action(:new).where(association_name: nil).first

        expect(@form.mandatory_validation_rules).to_not be_empty

        expect(@form.schema_instances.count).to_not eq 0
      end

    end

  end

  describe '.as_deep_json' do

    it 'should preload associations' do
      @schema = Dynamic::Schema.create!(name: 'my')
      @Contact = @schema.klasses.create!(name: 'Contact')
      @Contact.attrs.create!(name: 'first_name', type: 'String')
      @Contact.attrs.create!(name: 'last_name', type: 'String')
      @schema = @schema.class.find(@schema.id)

      includes = {
        "translations"=>{"except"=>["schema_id"]},
        "klasses"=>{
          "include"=>{
            "translations"=>{},
            "attrs"=>{"include"=>{"translations"=>{}, "values"=>{"include"=>{"translations"=>{}}}}},
            "associations"=>{"include"=>{"translations"=>{}}},
            "attachments"=>{"include"=>{"translations"=>{}}},
          }
        },
        "features"=> {
          "include"=>{
            "translations"=>{},
            "options"=>{"include"=>{"translations"=>{}}},
            "concerns"=>{
              "include"=>{
                "options"=>{"include"=>{"translations"=>{}}},
                "klass"=>{"include"=>{"schema"=>{"only"=>["name"]}}}
              }
            }
          }
        }
      }.with_indifferent_access

      expect {
        @schema.as_deep_json(include: includes, secure: false)
      }.to execute_query(/^SELECT "dynamic_schema_translations"/, max: 1)
      .and execute_query(/^SELECT "dynamic_schema_klasses"/, max: 1)
      .and execute_query(/^SELECT "dynamic_schema_klass_translations"/, max: 1)
      .and execute_query(/^SELECT "dynamic_schema_attributes"/, max: 1)
      .and execute_query(/^SELECT "dynamic_schema_attribute_translations"/, max: 1)
      .and execute_query(/^SELECT "dynamic_schema_attribute_enum_values"/, max: 1)
      .and execute_query(/^SELECT "dynamic_schema_associations"/, max: 1)
      .and execute_query(/^SELECT "dynamic_schema_association_translations"/, max: 1)
      .and execute_query(/^SELECT "dynamic_schema_attachments"/, max: 1)
      .and execute_query(/^SELECT "dynamic_schema_attachment_translations"/, max: 1)
      .and execute_query(/^SELECT "dynamic_schema_features"/, max: 1)
      .and execute_query(/^SELECT "dynamic_schema_feature_translations"/, max: 1)
      .and execute_query(/^SELECT "dynamic_schema_options"/, max: @schema.features.count)
      .and execute_query(/^SELECT "dynamic_schema_option_translations"/, max: @schema.features.count)
      .and execute_query(/^SELECT "dynamic_schema_concerns"/, max: @schema.features.count)
      .and execute_query(/^SELECT "dynamic_schema_concern_translations"/, max: @schema.features.count)
    end

  end

  describe '.drop_all_data' do
    before(:each) do
      @schema = Dynamic::Schema.create!(name: 'my')
      @schema.klasses.create!(name: 'Contact')

      @other_schema = Dynamic::Schema.create!(name: 'MyOther')
      @other_schema.klasses.create!(name: 'Contact')

      @schema.load
      @other_schema.load

      Dynamic::Elasticsearch.wait_for_complete do
        D::My::Contact.create!
        D::MyOther::Contact.create!
      end
    end

    it 'should remove data of sql tables of this schema' do
      expect{
        @schema.drop_all_data(true)
      }.to change {
        ActiveRecord::Base.connection.select_values('SELECT * FROM d_my_contacts').length
      }.to(0)
    end

    it 'should not remove data of sql tables of other schemas' do
      expect{
        @schema.drop_all_data(true)
      }.to_not change {
        ActiveRecord::Base.connection.select_values('SELECT * FROM d_myother_contacts').length
      }
    end

    it 'should remove data of elasticsearch indices of this schema' do
      expect{
        @schema.drop_all_data(true)
        ::OpenSearch::Model.refresh
      }.to change {
        D::My::Contact.search('*').to_a.length
      }.to(0)
    end

    it 'should remove data of elasticsearch indices of other schemas' do
      expect{
        @schema.drop_all_data(true)
        ::OpenSearch::Model.refresh
      }.to_not change {
        @other_schema.unload
        @other_schema.load
        D::MyOther::Contact.search('*').to_a.length
      }
    end

  end

end

