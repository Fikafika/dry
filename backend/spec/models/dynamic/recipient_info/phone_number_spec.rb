describe Dynamic::RecipientInfo::PhoneNumber, elasticsearch: false, sidekiq: false do
  before(:each) do
    User.current = User.create(last_name: 'toto', first_name: 'titi', login: 'super_toto')
    @schema = Dynamic::Schema.create!(name: 'my')
    @contact = @schema.klasses.create!(name: 'Contact')

    @communication_feature = @schema.features.find_by(name: 'Dynamic::Communication::Feature')
    @communication_feature.options.detect {|o| o.name == 'contact_klass'}.update!(value: @contact)
    @communication_feature.update!(enabled: true)
    @feature = @schema.features.find_by(name: 'Dynamic::RecipientInfo::Feature')
    @feature.update!(enabled: true)
    @schema.load
  end

  describe 'create' do
    before(:each) do
      @phone = D::My::Phone.create!(number: '+33612345678')
    end

    it 'should associate with a recipient phone' do
      expect(D::My::RecipientPhoneNumber.count).to eq(1)
      expect(@phone.recipient).to be_present
    end

    it 'should assign default values to recipient phone' do
      expect(@phone.recipient.info).to have_attributes(
        consent: false,
        npai: false,
        pressure: 0
      )
    end

    context 'with an existing recipient phone' do
      before(:each) do
        @phone = D::My::Phone.create!(number: '+33612345678')
      end

      it 'should associate with a recipient phone' do
        expect(D::My::RecipientPhoneNumber.count).to eq(1)
        expect(@phone.recipient).to be_present
      end

      it 'should assign default values to recipient phone' do
        expect(@phone.recipient.info).to have_attributes(
          consent: false,
          npai: false,
          pressure: 0
        )
      end

      context 'with an existing recipient phone' do
        before(:each) do
          @phone2 = D::My::Phone.create!(number: '+33612345678')
        end

        it 'should associate new phone with it' do
          expect(@phone.recipient).to eq(@phone2.recipient)
        end

        it 'should associate another phone to it' do
          expect(D::My::RecipientPhoneNumber.first.phones).to include(@phone, @phone2)
        end
      end

    end

    describe 'update' do
      before(:each) do
        @phone = D::My::Phone.create!(number: '+33612345678')
      end

      it 'should create another recipient phone' do
        expect{
          @phone.update(number: '+33611111111')
        }.to change{
          D::My::RecipientPhoneNumber.count
        }.by(1)
      end

      it 'should remove association from first recipient phone' do
        expect{
          @phone.update(number: '+33611111111')
        }.to change{
          D::My::RecipientPhoneNumber.first.phones.count
        }.by(-1)
      end

    end

    describe 'destroy' do
      before(:each) do
        @phone = D::My::Phone.create!(number: '+33612345678')
      end

      it 'should not destroy recipient phone' do
        expect{
          @phone.destroy!
        }.to_not change{
          D::My::RecipientPhoneNumber.count
        }
      end
    end
  end

  describe 'with mapping' do
    describe 'with base mapping' do
      before(:each) do
        phone_klass =  @schema.klasses.detect{|k| k.name == 'Phone'}
        number = phone_klass.attrs.detect{|a| a.name == 'number'}

        communication_feature = @schema.features.detect{|f| f.name == 'Dynamic::Communication::Feature'}
        phone_concern = communication_feature.concerns.detect {|c| c.name == 'Phone'}
        phone_concern.options.detect{|o| o.name == 'number_attribute'}.update!(value: number)

        @phone = D::My::Phone.create!(number: '+33612345678')
      end

      it 'should change RecipientPhoneNumber when number change' do
        expect(D::My::RecipientPhoneNumber.count).to eq(1)
        expect(@phone.recipient).to be_present
        expect(@phone.recipient.number).to eq('+33612345678')

        @phone.update!(number: '+33612345677')
        expect(D::My::RecipientPhoneNumber.count).to eq(2)
        expect(@phone.recipient).to be_present
        expect(@phone.recipient.number).to eq('+33612345677')
      end
    end

    describe 'with another mapping' do
      before(:each) do
        phone_klass = @schema.klasses.detect{|k| k.name == 'Phone'}
        number = phone_klass.attrs.create!(name: 'new_number', type: 'String')

        communication_feature = @schema.features.detect{|f| f.name == 'Dynamic::Communication::Feature'}
        phone_concern = communication_feature.concerns.detect {|c| c.name == 'Phone'}
        phone_concern.options.detect{|o| o.name == 'number_attribute'}.update!(value: number)
        @schema.load

        @phone = D::My::Phone.create!(number: '+33612345678', new_number: '+33612345677')
      end

      it 'should have RecipientPhoneNumber with values' do
        expect(D::My::RecipientPhoneNumber.count).to eq(1)
        expect(@phone.recipient).to be_present
        expect(@phone.recipient.number).to eq('+33612345677')
      end

      it 'shouldnt update RecipientPhoneNumber when changing old attributes' do
        @phone.update!(number: '+33612345679')
        expect(D::My::RecipientPhoneNumber.count).to eq(1)
        expect(@phone.recipient).to be_present
        expect(@phone.recipient.number).to eq('+33612345677')
      end

      it 'should update RecipientPhoneNumber when changing the new attributes' do
        @phone.update!(new_number: '+33612345679')
        expect(D::My::RecipientPhoneNumber.count).to eq(2)
        expect(@phone.recipient).to be_present
        expect(@phone.recipient.number).to eq('+33612345679')
      end
    end
  end

end
