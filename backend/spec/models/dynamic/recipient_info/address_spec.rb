describe Dynamic::RecipientInfo::Address, elasticsearch: false, sidekiq: false do
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
      @address = D::My::Address.create!(
        street: '3 rue des fraises',
        zip_code: '93000',
        city: 'Roubaix',
        country: 'France'
      )
    end

    it 'should assign default values to recipient info' do
      expect(@address.reload.info).to have_attributes(
        consent: false,
        npai: false,
        pressure: 0
      )
    end

    it 'should associate with recipient info' do
      expect(@address.reload.info.target).to eq(@address)
    end

  end

end
