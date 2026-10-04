describe Dynamic::Experience::Base, elasticsearch: false, sidekiq: false do
  before(:each) do
    @schema = Dynamic::Schema.create!(name: 'my')
    @feature = @schema.features.find_by(name: 'Dynamic::Experience::Feature')

    @account_klass = @schema.klasses.create!(name: 'Account', attrs_attributes: [{name: 'name', type: 'String'}])
    @contact_klass = @schema.klasses.create!(name: 'Contact', attrs_attributes: [{name: 'name', type: 'String'}])

    @concern = @feature.concerns.detect {|c| c.name == 'Job'}
    @feature.options.detect {|o| o.name == 'organization_klass'}.update!(value: @account_klass)
    @feature.options.detect {|o| o.name == 'owner_klass'}.update!(value: @contact_klass)
  end

  context 'with synchronize option' do
    before(:each) do
      @concern.options.detect {|o| o.name == 'synchronize'}.update!(value: true)
    end

    it 'should create attribute and association on contact klass' do
      @feature.update!(enabled: true)
      expect(@contact_klass.reload.attrs.map(&:name)).to contain_exactly('name', 'function')
      expect(@contact_klass.reload.associations.map(&:name)).to contain_exactly('organization', 'experiences', 'professional_experiences', 'trainings', 'volunteerings')
    end

    it 'should include synchronizable module on contact const klass' do
      @feature.update!(enabled: true)
      @schema.load
      expect(D::My::Contact.include?(Dynamic::Experience::Owner::Synchronizable)).to be true
    end

    it 'should include synchronizable module on job experience const klass' do
      @feature.update!(enabled: true)
      @schema.load
      expect(D::My::JobExperience.include?(Dynamic::Experience::Base::Synchronizable)).to be true
    end

  end

  context 'with finish previous option' do
    before(:each) do
      @concern.options.detect {|o| o.name == 'finish_previous'}.update!(value: true)
    end

    it 'should include finish_previous module on job experience const klass' do
      @feature.update!(enabled: true)
      @schema.load
      expect(D::My::JobExperience.include?(Dynamic::Experience::Base::FinishPrevious)).to be true
    end

  end

  describe 'use case' do
    before(:each) do
      @concern.options.detect {|o| o.name == 'synchronize'}.update!(value: true)
      @concern.options.detect {|o| o.name == 'finish_previous'}.update!(value: true)
      @feature.update!(enabled: true)
      @schema.load
    end

    context 'ongoing' do
      it 'should put ongoing to true if not given' do
        job_experience = D::My::JobExperience.create!(title: 'CEO')
        expect(D::My::JobExperience.first.ongoing).to eq(true)
      end

      it 'should let ongoing to false if given' do
        job_experience = D::My::JobExperience.create!(title: 'CEO', ongoing: false)
        expect(D::My::JobExperience.first.ongoing).to eq(false)
      end

      it 'shouldnt modify ongoing if updating title' do
        job_experience = D::My::JobExperience.create!(title: 'CEO', ongoing: true)
        expect(job_experience.ongoing).to eq(true)
        job_experience = job_experience.class.find(job_experience.id)
        job_experience.update!(title: 'Comptable')
        expect(job_experience.ongoing).to eq(true)

        job_experience = D::My::JobExperience.create!(title: 'CEO', ongoing: false)
        job_experience = job_experience.class.find(job_experience.id)
        expect(job_experience.ongoing).to eq(false)
        job_experience.update!(title: 'Comptable')
        expect(job_experience.ongoing).to eq(false)
      end

      it 'should create a job_experience with ongoing if only title given' do
        job_experience = D::My::JobExperience.create!(title: 'CEO')
        expect(job_experience.ongoing).to eq(true)
        expect(D::My::JobExperience.first.ongoing).to eq(true)
      end

      it 'should create a job_experience with ongoing if only account given' do
        account = D::My::Account.create!(name: 'Uneek')
        job_experience = D::My::JobExperience.create!(organization: account)
        expect(job_experience.ongoing).to eq(true)
        expect(D::My::JobExperience.first.ongoing).to eq(true)
      end

      it 'shouldnt create a new job_experience if changing the account' do
        contact = D::My::Contact.create!(name: 'Toto')
        account = D::My::Account.create!(name: 'Uneek')
        account_2 = D::My::Account.create!(name: 'Kosmopolead')
        job_experience = D::My::JobExperience.create!(title: 'CEO', owner: contact, organization: account, ongoing: true)

        job_experience = job_experience.class.find(job_experience.id)
        job_experience.update!(organization: account_2)
        expect(job_experience.ongoing).to eq(true)
        expect(contact.professional_experiences.count).to eq(1)
        expect(job_experience.organization.name).to eq(account_2.name)
      end

      it 'shouldnt delete the job_experience if we update its title to nil' do
        contact = D::My::Contact.create!(name: 'Toto')
        account = D::My::Account.create!(name: 'Uneek')
        job_experience = D::My::JobExperience.create!(title: 'CEO', owner: contact, organization: account, ongoing: true)

        job_experience = job_experience.class.find(job_experience.id)
        job_experience.update!(title: nil)
        contact.professional_experiences.reload
        expect(contact.professional_experiences.count).to eq(1)
        expect(D::My::Contact.first.professional_experiences.count).to eq(1)
      end

      it 'should add end_date when ongoing removed' do
        job_experience = D::My::JobExperience.create!(title: 'CEO', ongoing: true)
        expect(job_experience.ongoing).to eq(true)

        job_experience = job_experience.class.find(job_experience.id)
        job_experience.update!(ongoing: false)
        expect(job_experience.ongoing).to eq(false)
        expect(job_experience.end_date).to_not eq(nil)
      end

      it 'should remove end_date when ongoing added' do
        job_experience = D::My::JobExperience.create!(title: 'CEO', ongoing: false, end_date: Date.current)
        expect(job_experience.ongoing).to eq(false)
        expect(job_experience.end_date).to_not eq(nil)

        job_experience = job_experience.class.find(job_experience.id)
        job_experience.update!(ongoing: true)
        expect(job_experience.ongoing).to eq(true)
        expect(job_experience.end_date).to eq(nil)
      end

      xcontext 'with finish_previous', sidekiq: true do # Does not pass when performing async
        before(:each) do
          @contact = D::My::Contact.create!(name: 'Toto')
          @account_1 = D::My::Account.create!(name: 'Uneek')
          @account_2 = D::My::Account.create!(name: 'Kosmopolead')

          @job_experience_1 = D::My::JobExperience.create!(id: '01948db9-c946-7245-b03e-b38976c69951', title: 'Stagiaire', owner: @contact, organization: @account_1, ongoing: true)
          @job_experience_2 = D::My::JobExperience.create!(id: '01948db9-c9ad-735a-8ef7-70fc821c3b9c', title: 'CEO', owner: @contact, organization: @account_2, ongoing: true)
        end

        it 'should remove all ongoing when finish_previous' do
          job_experience = nil

          Dynamic::Elasticsearch.wait_for_complete do
            job_experience = D::My::JobExperience.create!(title: 'Unemployed', owner: @contact, finish_previous: true)
          end

          expect(job_experience.ongoing).to eq(true)
          expect(D::My::JobExperience.find(@job_experience_1.id).ongoing).to eq(false)
          expect(D::My::JobExperience.find(@job_experience_2.id).ongoing).to eq(false)
        end

        it 'should remove all main_company when finish_previous' do
          @job_experience_1.update!(main_organization: true)
          job_experience = nil

          Dynamic::Elasticsearch.wait_for_complete do
            job_experience = D::My::JobExperience.create!(title: 'Unemployed', owner: @contact, finish_previous: true)
          end

          expect(D::My::JobExperience.find(@job_experience_1.id).main_organization).to eq(false)
          expect(D::My::JobExperience.find(@job_experience_2.id).main_organization).to eq(false)
          expect(D::My::Contact.find(@job_experience_1.owner_id)).to have_attributes(
            function: 'Unemployed',
            organization: nil,
          )
        end

        it 'should update owner when finish_previous' do
          job_experience = nil

          expect(D::My::Contact.find(@job_experience_1.owner_id)).to have_attributes(
            function: 'CEO',
            organization: @account_2,
          )

          Dynamic::Elasticsearch.wait_for_complete do
            job_experience = D::My::JobExperience.create!(title: 'Unemployed', owner: @contact, finish_previous: true)
          end

          expect(D::My::Contact.find(@job_experience_1.owner_id)).to have_attributes(
            function: 'Unemployed',
            organization: nil,
          )
        end

        it 'should remove all ongoing when finish_previous (through contact association)' do
          job_experience = nil

          Dynamic::Elasticsearch.wait_for_complete do
            job_experience = @contact.professional_experiences.create!(title: 'Unemployed', finish_previous: true)
          end

          expect(job_experience.ongoing).to eq(true)
          expect(D::My::JobExperience.find(@job_experience_1.id).ongoing).to eq(false)
          expect(D::My::JobExperience.find(@job_experience_2.id).ongoing).to eq(false)
        end

        it 'shouldnt remove all ongoing when not finish_previous' do
          job_experience = D::My::JobExperience.create!(title: 'Unemployed', owner: @contact, finish_previous: nil)
          expect(job_experience.ongoing).to eq(true)
          expect(D::My::JobExperience.find(@job_experience_1.id).ongoing).to eq(true)
          expect(D::My::JobExperience.find(@job_experience_2.id).ongoing).to eq(true)

          job_experience = D::My::JobExperience.create!(title: 'Unemployed', owner: @contact, finish_previous: false)
          expect(job_experience.ongoing).to eq(true)
          expect(D::My::JobExperience.find(@job_experience_1.id).ongoing).to eq(true)
          expect(D::My::JobExperience.find(@job_experience_2.id).ongoing).to eq(true)
        end

        it 'should create versions with user as creator' do
          User.current = User.create!(login: 'toto@kosmopolead.com', email: 'toto@kosmopolead.com')
          job_experience = nil

          Dynamic::Elasticsearch.wait_for_complete do
            job_experience = D::My::JobExperience.create!(title: 'Unemployed', owner: @contact, finish_previous: true)
          end

          expect(job_experience.ongoing).to eq(true)
          expect(@job_experience_1.versions.count).to eq(2)
          expect(@job_experience_1.versions.last.whodunnit).to eq(User.current.id)
          expect(@job_experience_2.versions.last.whodunnit).to eq(User.current.id)
        end
      end

      context 'with end_date' do
        before(:each) do
          contact = D::My::Contact.create!(name: 'Toto')
          account_1 = D::My::Account.create!(name: 'Uneek')
          account_2 = D::My::Account.create!(name: 'Kosmopolead')

          @job_experience_1 = D::My::JobExperience.create!(title: 'Stagiaire', owner: contact, organization: account_1, ongoing: true)
          @job_experience_2 = D::My::JobExperience.create!(title: 'CEO', owner: contact, organization: account_2, ongoing: false, end_date: Date.current)
          @job_experience_3 = D::My::JobExperience.create!(title: 'Comptable', owner: contact, organization: account_2, ongoing: false)
        end

        it 'should remove ongoing if end_date added (from nil to past)' do
          @job_experience_1.update!(end_date: Date.current)
          expect(@job_experience_1.ongoing).to eq(false)
        end

        it 'should add ongoing if end_date removed (from past to nil)' do
          @job_experience_2.update!(end_date: nil)
          expect(@job_experience_2.ongoing).to eq(true)
        end

        it 'shouldnt add ongoing if updated while end_date nil' do
          @job_experience_3.update!(title: 'RH')
          expect(@job_experience_3.ongoing).to eq(false)
        end

        it 'should keep specified end date' do
          date = Date.current - 2.days
          @job_experience_1.update!(end_date: date)
          expect(@job_experience_1.end_date).to eq(date)
        end
      end

    end

    context 'organization/title' do
      before(:each) do
        @contact = D::My::Contact.create!(name: 'Toto')
        @account = D::My::Account.create!(name: 'Uneek')
      end

      context 'on create' do
        context 'main_organization true' do

          it 'should not put main_organization if ongoing' do
            job_experience = D::My::JobExperience.create!(title: 'CEO', owner: @contact, organization: @account, ongoing: true)
            expect(job_experience.reload.main_organization).to_not eq(true)
          end

          it 'should not put main_organization if no end_date' do
            job_experience = D::My::JobExperience.create!(title: 'CEO', owner: @contact, organization: @account)
            expect(job_experience.reload.main_organization).to_not eq(true)
          end

          it 'should put account in organization if main_organization' do
            job_experience = D::My::JobExperience.create!(title: 'CEO', owner: @contact, organization: @account, main_organization: true)
            expect(@contact.reload.organization.id).to eq(@account.id)
          end

          it 'should put title in contact title if main_organization' do
            job_experience = D::My::JobExperience.create!(title: 'CEO', owner: @contact, organization: @account, main_organization: true)
            expect(@contact.reload.function).to eq('CEO')
          end

          it 'should put title and organization (ongoing without other as main_organization)' do
            job_experience = D::My::JobExperience.create!(title: 'CEO', owner: @contact, organization: @account)
            @contact.reload
            expect(@contact.function).to eq('CEO')
            expect(@contact.organization.id).to eq(@account.id)
          end
        end

        context 'main_organization false' do
          it 'shouldnt put main_organization if main_organization false given' do
            job_experience = D::My::JobExperience.create!(title: 'CEO', owner: @contact, organization: @account, main_organization: false, ongoing: false)
            expect(job_experience.reload.main_organization).to eq(false)
          end

          it 'should remove main_organization if not ongoing but main_organization' do
            job_experience = D::My::JobExperience.create!(title: 'CEO', owner: @contact, organization: @account, main_organization: true, ongoing: false)
            expect(job_experience.reload.main_organization).to eq(false)
          end

          it 'shouldnt put title/organization in contact if main_organization but not ongoing' do
            job_experience = D::My::JobExperience.create!(title: 'CEO', owner: @contact, organization: @account, main_organization: true, ongoing: false)
            expect(@contact.reload.function).to eq(nil)
            expect(@contact.reload.organization).to eq(nil)
            expect(job_experience.reload.main_organization).to eq(false)
          end

          it 'shouldnt change other job experiences' do
            job_experience = D::My::JobExperience.create!(title: 'CEO', owner: @contact, organization: @account, main_organization: true)
            expect(job_experience.reload.main_organization).to eq(true)
            job_experience2 = D::My::JobExperience.create!(title: 'CEO', owner: @contact, organization: @account, main_organization: false)
            expect(job_experience.reload.main_organization).to eq(true)
            expect(job_experience2.reload.main_organization).to eq(false)
          end
        end
      end

      context 'on update' do
        context 'main_organization true' do
          it 'should update contact' do
            account2 = D::My::Account.create!(name: 'Kosmopolead')
            job_experience = D::My::JobExperience.create!(title: 'CEO', owner: @contact, organization: @account, main_organization: false, ongoing: false)

            expect(job_experience.reload.main_organization).to eq(false)

            job_experience = job_experience.class.find(job_experience.id)
            job_experience.update!(title: 'CTO', main_organization: true, ongoing: nil)
            expect(job_experience.reload.main_organization).to eq(true)
            expect(@contact.reload.function).to eq('CTO')

            job_experience = job_experience.class.find(job_experience.id)
            job_experience.update!(organization: account2)
            expect(@contact.reload.organization.id).to eq(account2.id)
          end

          it 'should remove main_organization from other job experiences' do
            account2 = D::My::Account.create!(name: 'Kosmopolead')
            job_experience = D::My::JobExperience.create!(title: 'CEO', owner: @contact, organization: @account, main_organization: true)
            job_experience2 = D::My::JobExperience.create!(title: 'CTO', owner: @contact, organization: @account, main_organization: false)
            expect(job_experience.reload.main_organization).to eq(true)
            expect(job_experience2.reload.main_organization).to eq(false)

            job_experience2 = job_experience2.class.find(job_experience2.id)
            job_experience2.update!(main_organization: true)
            expect(job_experience2.reload.main_organization).to eq(true)
            expect(job_experience.reload.main_organization).to eq(false)
          end
        end

        context 'main_organization false' do
          it 'shouldnt put main_organization if main_organization given false' do
            contact = D::My::Contact.create!(name: 'Toto')
            account = D::My::Account.create!(name: 'Uneek')
            job_experience = D::My::JobExperience.create!(title: 'CEO', owner: contact, organization: account, main_organization: false)

            job_experience = job_experience.class.find(job_experience.id)
            job_experience.update!(title: 'CTO', main_organization: false)
            expect(job_experience.reload.main_organization).to eq(false)
          end

          it 'should change contact function' do
            contact = D::My::Contact.create!(name: 'Toto')
            account = D::My::Account.create!(name: 'Uneek')
            job_experience = D::My::JobExperience.create!(title: 'CEO', owner: contact, organization: account, main_organization: false)

            job_experience = job_experience.class.find(job_experience.id)
            job_experience.update!(title: 'CTO', main_organization: false)
            expect(contact.reload.function).to eq('CTO')
          end

          it 'shouldnt remove main_organization from other job exeperiences' do
            account2 = D::My::Account.create!(name: 'Kosmopolead')
            job_experience = D::My::JobExperience.create!(title: 'CEO', owner: @contact, organization: @account, main_organization: true)
            job_experience2 = D::My::JobExperience.create!(title: 'CTO', owner: @contact, organization: @account, main_organization: false)
            expect(job_experience.reload.main_organization).to eq(true)
            expect(job_experience2.reload.main_organization).to eq(false)

            job_experience2 = job_experience2.class.find(job_experience2.id)
            job_experience2.update!(title: 'Intern', main_organization: false)
            expect(job_experience.reload.main_organization).to eq(true)
            expect(job_experience2.reload.main_organization).to eq(false)
          end

          it 'should remove main_organization if ongoing removed' do
            contact = D::My::Contact.create!(name: 'Toto')
            account = D::My::Account.create!(name: 'Uneek')
            job_experience = D::My::JobExperience.create!(title: 'CEO', owner: contact, organization: account, main_organization: true, ongoing: true)
            expect(job_experience.reload.main_organization).to eq(true)

            job_experience = job_experience.class.find(job_experience.id)
            job_experience.update!(ongoing: false)
            expect(job_experience.reload.main_organization).to eq(false)
          end
        end

        context 'making synchronized experience invalid' do
          before(:each) do
            account2 = D::My::Account.create!(name: 'Kosmopolead')
            D::My::JobExperience.create!(title: 'CEO', owner: @contact, organization: @account)
            @job_experience = D::My::JobExperience.create!(title: 'CTO', owner: @contact, organization: account2)

            expect(@contact.function).to eq('CTO')
            expect(@contact.organization).to eq(account2)
          end

          it 'should update contact when ongoing is set to false' do
            @job_experience.update!(ongoing: false)
            @contact.reload
            expect(@contact.function).to eq('CEO')
            expect(@contact.organization).to eq(@account)
          end

          it 'should update contact when end_date is specified' do
            @job_experience.update!(end_date: Date.current)
            @contact.reload
            expect(@contact.function).to eq('CEO')
            expect(@contact.organization).to eq(@account)
          end
        end
      end

      context 'on destroy' do
        it 'should remove function and organization from contact' do
          contact = D::My::Contact.create!(name: 'Toto')
          account = D::My::Account.create!(name: 'Uneek')

          job_experience = D::My::JobExperience.create!(title: 'CEO', owner: contact, organization: account)
          expect(contact.reload.function).to eq('CEO')
          expect(contact.reload.organization.id).to eq(account.id)

          job_experience = job_experience.class.find(job_experience.id)
          job_experience.destroy!
          expect(contact.reload.function).to eq(nil)
          expect(contact.reload.organization).to eq(nil)
        end
      end
    end
  end

end
