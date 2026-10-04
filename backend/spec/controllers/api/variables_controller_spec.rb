require "support/active_storage_helper"

describe Api::VariablesController, type: :controller, elasticsearch: false, sidekiq: false do
  include Devise::Test::ControllerHelpers
  include RSpec::ActiveStorage::Helper

  let(:user){User.create(login: "Login", email: "email@kosmopolead.com", uneek_sso_uuid: SecureRandom.uuid, super_admin: true)}
  let(:community){Community.create!(name: 'My', permalink: 'my')}
  let(:schema){community.schema}

  before(:each) do
    @klass = schema.klasses.create!(name: 'Klass', attrs_attributes: [{name: 'name', type: 'String'}])
    @klass.update!(name_attribute: @klass.attrs.detect{|a| a.name == 'name'})

    associated_klass = schema.klasses.create!(name: 'AssociatedKlass', attrs_attributes: [{name: 'name', type: 'String'}])
    associated_klass.update!(name_attribute: associated_klass.attrs.detect{|a| a.name == 'name'})

    @klass.associations.create!(name: 'associated', target_klass: associated_klass, type: 'BelongsTo')

    many_associated_klass = schema.klasses.create!(name: 'ManyAssociatedKlass', attrs_attributes: [{name: 'name', type: 'String'}, {name: 'price', type: 'Float'}])
    many_associated_klass.update!(name_attribute: many_associated_klass.attrs.detect{|a| a.name == 'name'})

    @klass.associations.create!(name: 'associateds', target_klass: many_associated_klass, type: 'HasMany')

    @klass.attachments.create!(name: 'one_attachment', type: 'HasOne')
    @klass.attachments.create!(name: 'many_attachment', type: 'HasMany')

    schema.load

    record = D::My::Klass.create!(name: 'term')
    record.associateds.create!([
      {name: 'Assoc1', price: 10},
      {name: 'Assoc2', price: 20.25},
    ])

    attach_fixture_file(record.one_attachment, 'file.jpg')
    attach_fixture_file(record.many_attachment, 'file.jpg')
    attach_fixture_file(record.many_attachment, 'file.pdf')

    record2 = D::My::Klass.create!(name: 'term2')

    record.associated = D::My::AssociatedKlass.create!(name: 'Contact')
    record.save

    @record_id = record.id
    @record_attach_content_type = record.one_attachment.blob.content_type
    @record2_id = record2.id

    @record_many_content_types = record.many_attachment.map {|a| a.blob.content_type}

    schema.unload

    request.env['devise.mapping'] = Devise.mappings[:user]
    sign_in(user)
  end

  describe "#index" do
    it 'routes GET /api/variables/d/:schema_name to variables#index' do
      expect(get: "/api/variables/d/my").to route_to(controller: 'api/variables', action: 'index', schema_name: 'my')
    end

    context "invalid payload" do
      context "schema_name" do
        it "empty should return error" do
          get :index, params: {schema_name: '', formula: 'toto', context: {"toto" => {klass: 'Klass', id: @record_id}}}
          expect(response).to have_http_status(422)
        end
      end

      context "formula" do
        it "as empty string should raise error" do
          get :index, params: {schema_name: 'my', formula: '', context: {"toto" => {klass: 'Klass', id: @record_id}}}
          expect(response).to have_http_status(422)
        end

        it "as empty array should raise error" do
          get :index, params: {schema_name: 'my', formula: [], context: {"toto" => {klass: 'Klass', id: @record_id}}}
          expect(response).to have_http_status(422)
        end

        it "as empty string in array should return empty string indexed by empty string" do
          get :index, params: {schema_name: 'my', formula: [''], context: {"toto" => {klass: 'Klass', id: @record_id}}}
          expect(response).to have_http_status(200)
          expect(response.parsed_body['result']).to eq({"" => ""})
        end

        it "missing should return error" do
          get :index, params: {schema_name: 'my', context: {"toto" => {klass: 'Klass', id: @record_id}}}
          expect(response).to have_http_status(422)
        end
      end

      context "context" do
        it 'empty should return error' do
          get :index, params: {schema_name: 'my', formula: 'toto', context: {}}
          expect(response).to have_http_status(422)
        end

        it 'missing should return error' do
          get :index, params: {schema_name: 'my', formula: 'toto'}
          expect(response).to have_http_status(422)
        end

        it 'without id should return error' do
          expect {
            get :index, params: {schema_name: 'my', formula: 'toto', context: {"toto" => {klass: 'Klass'}}}
          }.to raise_error(Api::VariablesController::RecordNotFoundError)
        end

        it 'without klass should return error' do
          get :index, params: {schema_name: 'my', formula: 'toto', context: {"toto" => {id: @record_id}}}
          expect(response).to have_http_status(422)
        end

        it "not found record should return error" do
          get :index, params: {schema_name: 'my', formula: 'toto', context: {"toto" => {klass: 'Klass', id: "xxxxx"}}}
          expect(response).to have_http_status(404)
          expect(response.parsed_body['result']).to eq("Record for 'toto' not found")
        end

        it "invalid klass should return error" do
          get :index, params: {schema_name: 'my', formula: 'toto', context: {"toto" => {klass: 'InvalidKlass', id: "xxxxx"}}}
          expect(response).to have_http_status(422)
          expect(response.parsed_body['result']).to eq("Klass 'InvalidKlass' is not defined")
        end
      end
    end

    context "single variable in formula" do
      it 'should return a record value' do
        get :index, params: {schema_name: 'my', formula: 'toto', context: {"toto" => {klass: 'Klass', id: @record_id}}}
        expect(response).to have_http_status(200)
        expect(response.parsed_body['result']).to eq("term")
      end

      it 'should return a attribute value' do
        get :index, params: {schema_name: 'my', formula: 'toto.name', context: {"toto" => {klass: 'Klass', id: @record_id}}}
        expect(response).to have_http_status(200)
        expect(response.parsed_body['result']).to eq('term')
      end

      it 'accessing field on string should return empty string' do
        get :index, params: {schema_name: 'my', formula: 'toto.name.inexistent', context: {"toto" => {klass: 'Klass', id: @record_id}}}
        expect(response).to have_http_status(200)
        expect(response.parsed_body['result']).to eq('')
      end

      it 'accessing inexistent field should return empty string' do
        get :index, params: {schema_name: 'my', formula: 'toto.inexistent', context: {"toto" => {klass: 'Klass', id: @record_id}}}
        expect(response).to have_http_status(200)
        expect(response.parsed_body['result']).to eq('')
      end

      it 'should return the value even with multiple method calls' do
        get :index, params: {schema_name: 'my', formula: 'toto.associated.name', context: {"toto" => {klass: 'Klass', id: @record_id}}}
        expect(response).to have_http_status(200)
        expect(response.parsed_body['result']).to eq('Contact')
      end
    end

    context "on type many association" do
      it 'accessing specific index should return the value' do
        get :index, params: {schema_name: 'my', formula: 'toto.associateds@0.name', context: {"toto" => {klass: 'Klass', id: @record_id}}}
        expect(response).to have_http_status(200)
        expect(response.parsed_body['result']).to eq('Assoc1')
      end

      it 'accessing inexistent specific index should return empty string' do
        get :index, params: {schema_name: 'my', formula: 'toto.associateds@2.name', context: {"toto" => {klass: 'Klass', id: @record_id}}}
        expect(response).to have_http_status(200)
        expect(response.parsed_body['result']).to eq('')
      end

      it 'accessing inexistent association and index should return empty string' do
        get :index, params: {schema_name: 'my', formula: 'toto.invalid_associateds@2.name', context: {"toto" => {klass: 'Klass', id: @record_id}}}
        expect(response).to have_http_status(200)
        expect(response.parsed_body['result']).to eq('')
      end

      it "accessing field without specific index should return all values as array" do
        get :index, params: {schema_name: 'my', formula: 'toto.associateds.name', context: {"toto" => {klass: 'Klass', id: @record_id}}}
        expect(response).to have_http_status(200)
        expect(response.parsed_body['result']).to eq(['Assoc1', 'Assoc2'])
      end

      it "accessing association without specific index nor field should return all attribute_names values as array" do
        get :index, params: {schema_name: 'my', formula: 'toto.associateds', context: {"toto" => {klass: 'Klass', id: @record_id}}}
        expect(response).to have_http_status(200)
        expect(response.parsed_body['result']).to eq(['Assoc1', 'Assoc2'])
      end
    end

    context "on variable attachment" do
      context "with has_one" do
        it 'should return the specified attachment field' do
          get :index, params: {schema_name: 'my', attachment_key: "blob.content_type", formula: 'toto.one_attachment', context: {"toto" => {klass: 'Klass', id: @record_id}}}
          expect(response).to have_http_status(200)
          expect(response.parsed_body['result']).to eq(@record_attach_content_type)
        end

        it 'should use blob.filename attachment key if not provided' do
          get :index, params: {schema_name: 'my', formula: 'toto.one_attachment', context: {"toto" => {klass: 'Klass', id: @record_id}}}
          expect(response).to have_http_status(200)
          expect(response.parsed_body['result']).to eq("file.jpg")
        end
      end

      context "with has_many" do
        it 'should return the specified attachment field of each item in the collection' do
          get :index, params: {schema_name: 'my', attachment_key: "blob.content_type", formula: 'toto.many_attachment', context: {"toto" => {klass: 'Klass', id: @record_id}}}
          expect(response).to have_http_status(200)
          expect(response.parsed_body['result']).to eq(@record_many_content_types)
        end

        it 'blob.filename attachment key if not provided' do
          get :index, params: {schema_name: 'my', formula: 'toto.many_attachment', context: {"toto" => {klass: 'Klass', id: @record_id}}}
          expect(response).to have_http_status(200)
          expect(response.parsed_body['result']).to eq(["file.jpg", "file.pdf"])
        end
      end
    end

    context "with array of formula" do
      it "should return hash indexed by formula" do
        get :index, params: {schema_name: 'my', formula: ['toto', 'toto.name', 'toto.associateds.name', 'toto.one_attachment'], context: {"toto" => {klass: 'Klass', id: @record_id}}}
        expect(response).to have_http_status(200)
        expect(response.parsed_body['result']).to eq({
          "toto" => "term",
          "toto.name" => "term",
          "toto.associateds.name" => ['Assoc1', 'Assoc2'],
          "toto.one_attachment" => "file.jpg"
        })
      end
    end

    context "using formula" do
      it 'should return blank if incorrect formula' do
        get :index, params: {schema_name: 'my', formula: 'toto +', context: {"toto" => {klass: 'Klass', id: @record_id}}}
        expect(response).to have_http_status(200)
        expect(response.parsed_body['result']).to be_blank
      end

      context "with concatenation" do
        it 'should be evaluated' do
          get :index, params: {schema_name: 'my', formula: 'toto.name + titi.name', context: {"toto" => {klass: 'Klass', id: @record_id}, "titi" => {klass: 'Klass', id: @record2_id}}}
          expect(response).to have_http_status(200)
          expect(response.parsed_body['result']).to eq('termterm2')
        end
      end

      context "with function" do
        context "len()" do
          it 'should be evaluated' do
            get :index, params: {schema_name: 'my', formula: 'len(toto.name)', context: {"toto" => {klass: 'Klass', id: @record_id}}}
            expect(response).to have_http_status(200)
            expect(response.parsed_body['result'].to_s).to eq('4')
          end
        end

        context "count()" do
          it 'should be evaluated' do
            get :index, params: {schema_name: 'my', formula: 'count(toto.associateds)', context: {"toto" => {klass: 'Klass', id: @record_id}}}
            expect(response).to have_http_status(200)
            expect(response.parsed_body['result'].to_s).to eq('2')
          end
        end

        context "sum()" do
          it 'should be evaluated' do
            get :index, params: {schema_name: 'my', formula: 'sum(toto.associateds.price)', context: {"toto" => {klass: 'Klass', id: @record_id}}}
            expect(response).to have_http_status(200)
            expect(response.parsed_body['result'].to_s).to eq('30.25')
          end
        end
      end
    end

    context 'with permissions' do
      let(:user){User.create!(login: 'Login', email: 'email@kosmopolead.com', uneek_sso_uuid: SecureRandom.uuid)}
      let(:rule){UneekPermission::Rule.create!(receiver: user, klass_name: schema.klasses.first.const_absolute_name, permission: '_R__', schema: schema)}

      before(:each) do
        rule
      end

      context 'on klass' do

        it 'should be evaluated' do
          get :index, params: {schema_name: 'my', formula: 'toto', context: {'toto' => {klass: 'Klass', id: @record_id}}}
          expect(response).to have_http_status(200)
          expect(response.parsed_body['result']).to eq('term')
        end
      end

      context 'on unauthorized klass' do
        let(:rule){}

        it 'should return empty result' do
          get :index, params: {schema_name: 'my', formula: 'toto', context: {'toto' => {klass: 'Klass', id: @record_id}}}
          expect(response).to have_http_status(200)
          expect(response.parsed_body['result']).to be_empty
        end
      end

      context 'on invalid parameters' do

        it 'should return 422 on invalid klass' do
          get :index, params: {schema_name: 'my', formula: 'toto', context: {'toto' => {klass: 'School', id: @record_id}}}
          expect(response).to have_http_status(422)
        end

        it 'should return empty result on invalid id' do
          get :index, params: {schema_name: 'my', formula: 'toto', context: {'toto' => {klass: 'Klass', id: 'not_an_id'}}}
          expect(response).to have_http_status(404)
        end

      end
    end
  end
end
