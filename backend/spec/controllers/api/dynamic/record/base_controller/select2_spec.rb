describe Api::Dynamic::Record::BaseController::Select2 do
  describe 'klasses' do
    before(:each) do
      @community = Community.create!(name: 'My', permalink: 'my')
      @schema = Dynamic::Schema.first
      @schema.klasses.create!([
        {
          name: 'Record',
          attrs_attributes: [{
            name: 'name',
            type: 'String',
          }]
        },
        {
          name: 'Contact',
          attrs_attributes: [{
            name: 'name',
            type: 'String',
          }]
        },
        {
          name: 'Account',
          attrs_attributes: [{
            name: 'name',
            type: 'String',
          }]
        },
      ])

      @schema.load

      ::Dynamic::Elasticsearch.wait_for_complete do
        @record = D::My::Record.create!(name: 'term')
        @record2 = D::My::Contact.create!(name: 'term')
        @record3 = D::My::Account.create!(name: 'term')
      end

      User.current =  User.create!(login: "Login", email: "email@kosmopolead.com", super_admin: true)
    end

    it 'should search if given a klass' do
      params = {term: 'term', schema_name: @schema.name}.with_indifferent_access
      results = Api::Dynamic::Record::BaseController::Select2.new(D::My::Record, params).to_json[:results].map{|x| x[:id]}
      expect(results[0]).to eq @record.id
      expect(results.length).to eq 1
    end

    it 'should search if given an array' do
      params = {term: 'term', schema_name: @schema.name}.with_indifferent_access
      results = Api::Dynamic::Record::BaseController::Select2.new([D::My::Record], params).to_json[:results].map{|x| x[:id]}
      expect(results[0]).to eq @record.id
      expect(results.length).to eq 1
    end

    it 'should only search on the klasses given' do
      params = {term: 'term', schema_name: @schema.name}.with_indifferent_access
      results = Api::Dynamic::Record::BaseController::Select2.new([D::My::Record, D::My::Contact], params).to_json[:results].map{|x| x[:id]}
      expect(results.length).to eq 2
      expect(results).to include(@record.id)
      expect(results).to include(@record2.id)
      expect(results).to_not include(@record3.id)
    end

    it 'should search all records if klasses is nil' do
      params = {term: 'term', schema_name: @schema.name}.with_indifferent_access
      results = Api::Dynamic::Record::BaseController::Select2.new(nil, params).to_json[:results].map{|x| x[:id]}
      expect(results.length).to eq 3
      expect(results).to include(@record.id)
      expect(results).to include(@record2.id)
      expect(results).to include(@record3.id)
    end

    it 'should not search all records if klasses is []' do
      params = {term: 'term', schema_name: @schema.name}.with_indifferent_access
      results = Api::Dynamic::Record::BaseController::Select2.new([], params).to_json[:results].map{|x| x[:id]}
      expect(results.length).to eq 3
      expect(results).to include(@record.id)
      expect(results).to include(@record2.id)
      expect(results).to include(@record3.id)
    end

  end

  describe 'filters' do # TODO create a gem dynamic-filters ?
    before(:each) do
      @schema = Dynamic::Schema.create!(name: 'my')
      @Contact = @schema.klasses.create!(
        name: 'Contact',
        attrs_attributes: [{
          name: 'name',
          type: 'String',
        }],
      )
      @Email = @schema.klasses.create!(
        name: 'Email',
        attrs_attributes: [{
          name: 'address',
          type: 'String',
        }],
      )
      @Contact.associations.create!(name: 'emails', target_klass: @Email , type: 'HasMany')

      @schema.load
    end

    describe 'bool' do

      it 'and' do
        ::Dynamic::Elasticsearch.wait_for_complete do
          @record1 = D::My::Contact.create!(name: 'A', emails_attributes: [{address: 'a@a.fr'}])
          @record2 = D::My::Contact.create!(name: 'A', emails_attributes: [{address: 'a2@a.fr'}])
        end
        params = {schema_name: @schema.name, filters: {and: [{name: {equal: 'A'}}, {'emails.address': {equal: 'a@a.fr'}}]}}.with_indifferent_access
        results = Api::Dynamic::Record::BaseController::Select2.new([D::My::Contact], params).to_json[:results].map{|x| x[:id]}
        expect(results.length).to eq 1
        expect(results).to include(@record1.id)
      end

      it 'should work even if not normalized' do
        ::Dynamic::Elasticsearch.wait_for_complete do
          @record1 = D::My::Contact.create!(name: 'A')
          @record2 = D::My::Contact.create!(name: 'B')
        end
        params = {schema_name: @schema.name, filters: {or: [{and: [{or: [{and: [{name: {equal: 'A'}}, {name: {equal: 'A'}}]}]}]}]}}.with_indifferent_access
        results = Api::Dynamic::Record::BaseController::Select2.new([D::My::Contact], params).to_json[:results].map{|x| x[:id]}
        expect(results.length).to eq 1
        expect(results).to include(@record1.id)
      end

    end

    describe 'operators' do

      it 'equal' do
        ::Dynamic::Elasticsearch.wait_for_complete do
          @record1 = D::My::Contact.create!(name: 'A 1')
          @record2 = D::My::Contact.create!(name: 'A 2')
        end
        params = {schema_name: @schema.name, filters: {'name': {equal: 'A 1'}}}.with_indifferent_access
        results = Api::Dynamic::Record::BaseController::Select2.new([D::My::Contact], params).to_json[:results].map{|x| x[:id]}
        expect(results.length).to eq 1
        expect(results).to include(@record1.id)
      end

      it 'contains_id' do
        ::Dynamic::Elasticsearch.wait_for_complete do
          @record1 = D::My::Contact.create!(name: 'A', emails_attributes: [{address: 'a@a.fr'}])
          @record2 = D::My::Contact.create!(name: 'B', emails_attributes: [{address: 'b@b.fr'}])
        end
        @email1_id = @record1.emails.first.id
        params = {schema_name: @schema.name, filters: {'emails': {contains_id: @email1_id}}}.with_indifferent_access
        results = Api::Dynamic::Record::BaseController::Select2.new([D::My::Contact], params).to_json[:results].map{|x| x[:id]}
        expect(results.length).to eq 1
        expect(results).to include(@record1.id)
      end

    end

    describe 'variables' do

      it 'should replace a variable by its value' do
        ::Dynamic::Elasticsearch.wait_for_complete do
          @record1 = D::My::Contact.create!(name: 'A 1')
          @record2 = D::My::Contact.create!(name: 'A 2')
        end
        params = {schema_name: @schema.name, filters: {'name': {equal: {variable: 'my_variable'}}}, variables: {my_variable: 'A 1'}}.with_indifferent_access
        results = Api::Dynamic::Record::BaseController::Select2.new([D::My::Contact], params).to_json[:results].map{|x| x[:id]}
        expect(results.length).to eq 1
        expect(results).to include(@record1.id)
      end

    end

  end

  describe 'association default filters' do
    before(:each) do
      @schema = Dynamic::Schema.create!(name: 'my')
      @Contact = @schema.klasses.create!(
        name: 'Contact',
        attrs_attributes: [{name: 'name', type: 'String'}],
      )
      @Company = @schema.klasses.create!(
        name: 'Company',
        attrs_attributes: [{name: 'name', type: 'String'}],
      )
      @Fonction = @schema.klasses.create!(
        name: 'Fonction',
        attrs_attributes: [{name: 'name', type: 'String'}],
      )
      @Contact.associations.create!(name: 'company', target_klass: @Company, type: 'BelongsTo')
      @Fonction.associations.create!(
        name: 'contact',
        target_klass: @Contact,
        type: 'BelongsTo',
        default_elasticsearch_filters: {'company.id' => {'equal' => {'variable' => 'company'}}},
      )

      @schema.load

      ::Dynamic::Elasticsearch.wait_for_complete do
        @company1 = D::My::Company.create!(name: 'C 1')
        @company2 = D::My::Company.create!(name: 'C 2')
        @contact1 = D::My::Contact.create!(name: 'A', company: @company1)
        @contact2 = D::My::Contact.create!(name: 'B', company: @company2)
      end

      @base_params = {
        schema_name: @schema.name,
        owner_klass_name: 'D::My::Fonction',
        association_name: 'contact',
      }
    end

    def select2_results(params)
      Api::Dynamic::Record::BaseController::Select2.new([D::My::Contact], params.with_indifferent_access).to_json[:results].map{|x| x[:id]}
    end

    it 'should apply the default filters with the provided variable' do
      results = select2_results(@base_params.merge(variables: {company: @company1.id}))
      expect(results).to eq [@contact1.id]
    end

    it 'should return nothing when the variable is provided but blank' do
      results = select2_results(@base_params.merge(variables: {company: nil}))
      expect(results).to eq []
    end

    it 'should use only the params filters when they are present and ignore the default filters' do
      results = select2_results(@base_params.merge(
        variables: {company: @company1.id},
        filters: {name: {equal: 'B'}}, # contact2, while the default filters would match contact1
      ))
      expect(results).to eq [@contact2.id]
    end
  end

end
