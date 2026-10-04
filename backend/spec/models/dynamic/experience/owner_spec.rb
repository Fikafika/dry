describe Dynamic::Experience::Owner, elasticsearch: false, sidekiq: false do
  before(:each) do
    @schema = Dynamic::Schema.create!(name: 'my')
    feature = @schema.features.find_by(name: 'Dynamic::Experience::Feature')

    @account_klass = @schema.klasses.create!(name: 'Account', attrs_attributes: [{name: 'name', type: 'String'}])
    @contact_klass = @schema.klasses.create!(name: 'Contact', attrs_attributes: [{name: 'name', type: 'String'}])

    @concern = feature.concerns.detect {|c| c.name == 'Job'}
    feature.options.detect {|o| o.name == 'organization_klass'}.update!(value: @account_klass)
    feature.options.detect {|o| o.name == 'owner_klass'}.update!(value: @contact_klass)
    @concern.options.detect {|o| o.name == 'synchronize'}.update!(value: true)

    feature.update!(enabled: true)
    @schema.load
  end

  context 'new contact' do
    it 'should create a new main_organization professional_experiences if organization or function is given' do
      account = D::My::Account.create!(name: 'Uneek')
      contact = D::My::Contact.create!(name: 'Toto', organization: account)
      expect(contact.professional_experiences.count).to eq(1)
      expect(contact.professional_experiences.first.organization.id).to eq(account.id)

      contact2 = D::My::Contact.create!(name: 'Tutu', function: 'CEO')
      expect(contact2.professional_experiences.count).to eq(1)
      expect(contact2.professional_experiences.first.title).to eq('CEO')

      contact3 = D::My::Contact.create!(name: 'Tata', organization: account, function: 'CEO')
      expect(contact3.professional_experiences.count).to eq(1)
      expect(contact3.professional_experiences.first.organization.id).to eq(account.id)
      expect(contact3.professional_experiences.first.title).to eq('CEO')
    end

    it 'shouldnt create a new professional_experiences if organization and function not given' do
      contact = D::My::Contact.create!(name: 'Toto')
      expect(contact.professional_experiences.count).to eq(0)
    end
  end

  context 'updated contact' do
    context 'no main_organization job experience' do
      before(:each) do
        @contact = D::My::Contact.create!(name: 'Toto')
        @account = D::My::Account.create!(name: 'Uneek')
      end

      it 'should create a new job experience if organization given' do
        @contact.update!(organization: @account)
        @contact.professional_experiences.reload
        expect(@contact.professional_experiences.count).to eq(1)
        expect(@contact.professional_experiences.first.organization.id).to eq(@account.id)
      end

      it 'should create a new job experience if function given' do
        @contact.update!(function: 'CEO')
        expect(@contact.professional_experiences.count).to eq(1)
        expect(@contact.professional_experiences.first.title).to eq('CEO')
      end

      it 'should create only one new job experience if function and organization given' do
        @contact.update!(organization: @account, function: 'CEO')
        @contact.professional_experiences.reload
        expect(@contact.professional_experiences.count).to eq(1)
        expect(@contact.professional_experiences.first.organization.id).to eq(@account.id)
        expect(@contact.professional_experiences.first.title).to eq('CEO')
      end

      it 'should update opensearch document', elasticsearch: true, sidekiq: true do
        Dynamic::Elasticsearch.wait_for_complete do
          @contact.update!(organization: @account)
        end
        expect(@contact.__opensearch__.source).to include('organization')
      end
    end

    context 'updating experiences' do
      before(:each) do
        @account = D::My::Account.create!(name: 'Uneek')
        @contact = D::My::Contact.create!(name: 'Toto', organization: @account, function: 'CEO')
        @contact = @contact.class.find(@contact.id)
      end

      it 'should remove function and organization when removing all experiences' do
        @contact.update!(professional_experiences: [])
        expect(@contact.professional_experiences.count).to eq(0)
        expect(@contact.function).to be nil
        expect(@contact.organization).to be nil
      end

      it 'should update function and organization when adding new record (nested_attributes)' do
        @account2 = D::My::Account.create!(name: 'Toto & co')

        @contact.update!(professional_experiences_attributes: [
            {title: 'CTO', organization: @account2}
          ]
        )
        expect(@contact.professional_experiences.count).to eq(2)
        expect(@contact.function).to eq('CTO')
        expect(@contact.organization).to eq(@account2)
      end

      it 'should not update function and organization when adding an existing experience' do
        @account2 = D::My::Account.create!(name: 'Toto & co')
        job_experience = D::My::JobExperience.create!(title: 'CTO', organization: @account2)

        @contact.professional_experiences << job_experience
        expect(@contact.professional_experiences.count).to eq(2)
        expect(@contact.function).to eq('CTO')
        expect(@contact.organization).to eq(@account2)
      end

      it 'should update function and organization when adding an existing main_organization experience' do
        @account2 = D::My::Account.create!(name: 'Toto & co')
        job_experience = D::My::JobExperience.create!(title: 'CTO', organization: @account2, main_organization: true)

        @contact.professional_experiences << job_experience
        expect(@contact.professional_experiences.count).to eq(2)
        expect(@contact.function).to eq('CTO')
        expect(@contact.organization).to eq(@account2)
      end

      it 'should update function and organization with another experience when removing a single one' do
        @account2 = D::My::Account.create!(name: 'Toto & co')
        job_experience = D::My::JobExperience.create!(title: 'CTO', organization: @account2)

        @contact.professional_experiences << job_experience

        @contact = @contact.class.find(@contact.id)
        @contact.update!(professional_experiences: [job_experience])
        expect(@contact.professional_experiences.count).to eq(1)
        expect(@contact.function).to eq('CTO')
        expect(@contact.organization).to eq(@account2)
      end
    end

  end

end
