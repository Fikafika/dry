describe Dynamic::RecipientInfo::EmailAddress, elasticsearch: false, sidekiq: false do
  before(:each) do
    User.current = User.create(last_name: 'toto', first_name: 'titi', login: 'super_toto')
    @schema = Dynamic::Schema.create!(name: 'my')
    @contact = @schema.klasses.create!(name: 'Contact')

    @feature = @schema.features.find_by!(name: 'Dynamic::RecipientInfo::Feature')
    @communication_feature = @schema.features.find_by!(name: 'Dynamic::Communication::Feature')
    @communication_feature.options.detect {|o| o.name == 'contact_klass'}.update!(value: @contact)
    @communication_feature.update!(enabled: true)
    @feature.update!(enabled: true)
    @schema.load
  end

  describe 'create' do
    before(:each) do
      @email = D::My::Email.create!(address: 'toto@mail.com', consent: true, npai: false)
    end

    it 'should associate with a recipient email' do
      expect(D::My::RecipientEmailAddress.count).to eq(1)
      expect(@email.recipient).to be_present
    end

    it 'should assign default values to recipient email' do
      expect(@email.recipient.info).to have_attributes(
        consent: true,
        npai: false,
        pressure: 0
      )
    end

    context 'with an existing recipient email' do
      before(:each) do
        @email = D::My::Email.create!(address: 'toto@mail.com', consent: true, npai: false)
      end

      it 'should associate with a recipient email' do
        expect(D::My::RecipientEmailAddress.count).to eq(1)
        expect(@email.recipient).to be_present
      end

      it 'should assign default values to recipient email' do
        expect(@email.recipient.info).to have_attributes(
          consent: true,
          npai: false,
          pressure: 0
        )
      end

      context 'with an existing recipient email' do
        before(:each) do
          @email2 = D::My::Email.create!(address: 'toto@mail.com')
        end

        it 'should associate new email with it' do
          expect(@email.recipient).to eq(@email2.recipient)
        end

        it 'should associate another email to it' do
          expect(D::My::RecipientEmailAddress.first.emails).to include(@email, @email2)
        end
      end

    end

    describe 'update' do
      before(:each) do
        @email = D::My::Email.create!(address: 'toto@mail.com')
      end

      it 'should create another recipient email' do
        expect{
          @email.update(address: 'tutu@mail.com')
        }.to change{
          D::My::RecipientEmailAddress.count
        }.by(1)
      end

      it 'should remove association from first recipient email' do
        expect{
          @email.update(address: 'tutu@mail.com')
        }.to change{
          D::My::RecipientEmailAddress.first.emails.count
        }.by(-1)
      end

      it 'should update recipient info when changing email consent' do
        expect{
          @email.update(consent: true)
        }.to change{
          @email.recipient.info.consent
        }.from(nil).to(true)
      end

      it 'should update recipient info when changing email npai' do
        expect{
          @email.update(npai: true)
        }.to change{
          @email.recipient.info.npai
        }.from(nil).to(true)
      end

    end

    describe 'destroy' do
      before(:each) do
        @email = D::My::Email.create!(address: 'toto@mail.com')
      end

      it 'should not destroy recipient email' do
        expect{
          @email.destroy!
        }.to_not change{
          D::My::RecipientEmailAddress.count
        }
      end
    end
  end

  describe 'with mapping' do
    describe 'with base mapping' do
      before(:each) do
        email_klass =  @schema.klasses.detect{|k| k.name == 'Email'}
        address = email_klass.attrs.detect{|a| a.name == 'address'}
        consent = email_klass.attrs.detect{|a| a.name == 'consent'}
        npai = email_klass.attrs.detect{|a| a.name == 'npai'}

        communication_feature = @schema.features.detect{|f| f.name == 'Dynamic::Communication::Feature'}
        email_concern = communication_feature.concerns.detect {|c| c.name == 'Email'}
        email_concern.options.detect{|o| o.name == 'address_attribute'}.update!(value: address)
        email_concern.options.detect{|o| o.name == 'consent_attribute'}.update!(value: consent)
        email_concern.options.detect{|o| o.name == 'npai_attribute'}.update!(value: npai)

        @email = D::My::Email.create!(address: 'toto@mail.com', consent: true, npai: false)
      end

      it 'should change RecipientEmailAddress when address change' do
        expect(D::My::RecipientEmailAddress.count).to eq(1)
        expect(@email.recipient).to be_present
        expect(@email.recipient.address).to eq('toto@mail.com')

        @email.update!(address: 'toto+1@mail.com')
        expect(D::My::RecipientEmailAddress.count).to eq(2)
        expect(@email.recipient).to be_present
        expect(@email.recipient.address).to eq('toto+1@mail.com')
      end

      it 'should change RecipientEmailAddress when consent and npai change' do
        expect(D::My::RecipientEmailAddress.count).to eq(1)
        expect(@email.recipient).to be_present
        expect(@email.recipient.info).to have_attributes(
          consent: true,
          npai: false,
        )

        @email.update!(consent: false)
        expect(D::My::RecipientEmailAddress.count).to eq(1)
        expect(@email.recipient).to be_present
        expect(@email.recipient.info).to have_attributes(
          consent: false,
          npai: false,
        )

        @email.update!(npai: true)
        expect(D::My::RecipientEmailAddress.count).to eq(1)
        expect(@email.recipient).to be_present
        expect(@email.recipient.info).to have_attributes(
          consent: false,
          npai: true,
        )
      end

    end

    describe 'with another mapping' do
      before(:each) do
        email_klass =  @schema.klasses.detect{|k| k.name == "Email"}
        address = email_klass.attrs.create!(name: 'new_address', type: 'String')
        consent = email_klass.attrs.create!(name: 'new_consent', type: 'Boolean')
        npai = email_klass.attrs.create!(name: 'new_npai', type: 'Boolean')

        communication_feature = @schema.features.detect{|f| f.name == 'Dynamic::Communication::Feature'}
        email_concern = communication_feature.concerns.detect {|c| c.name == 'Email'}
        email_concern.options.detect{|o| o.name == 'address_attribute'}.update!(value: address)
        email_concern.options.detect{|o| o.name == 'consent_attribute'}.update!(value: consent)
        email_concern.options.detect{|o| o.name == 'npai_attribute'}.update!(value: npai)
        @schema.load

        @email = D::My::Email.create!(address: 'toto@mail.com', new_address: 'titi@mail.com', consent: true, new_consent: nil, npai: false, new_npai: nil)
      end

      it 'should have RecipientEmailAddress with values' do
        expect(D::My::RecipientEmailAddress.count).to eq(1)
        expect(@email.recipient).to be_present
        expect(@email.recipient.address).to eq('titi@mail.com')
        expect(@email.recipient.info).to have_attributes(
          consent: nil,
          npai: nil,
        )
      end

      it 'shouldnt update RecipientEmailAddress when changing old attributes' do
        @email.update!(address: 'toto+1@mail.com', consent: false, npai: true)

        expect(D::My::RecipientEmailAddress.count).to eq(1)
        expect(@email.recipient).to be_present
        expect(@email.recipient.address).to eq('titi@mail.com')
        expect(@email.recipient.info).to have_attributes(
          consent: nil,
          npai: nil,
        )
      end

      it 'should update RecipientEmailAddress when changing the new attributes' do
        @email.update!(new_address: 'titi+1@mail.com', new_consent: false, new_npai: true)

        expect(D::My::RecipientEmailAddress.count).to eq(2)
        expect(@email.recipient).to be_present
        expect(@email.recipient.address).to eq('titi+1@mail.com')
        expect(@email.recipient.info).to have_attributes(
          consent: false,
          npai: true,
        )
      end
    end
  end
end
