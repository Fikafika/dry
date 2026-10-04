describe Dynamic::Company::Worker, sidekiq: false do
  before(:each) do
    @user = User.create!(last_name: 'albert', email: 'albert@mousquetaire.fr', login: 'albert@mousquetaire.fr')
    User.current = @user

    @schema = Dynamic::Schema.create!(name: 'my')
    @establissement_klass = @schema.klasses.create!(name: 'Establissement', attrs_attributes: [
      {name: 'denomination', type: 'String'},
      {name: 'siret', type: 'String'},
    ])

    @feature = @schema.features.find_by(name: 'Dynamic::Company::Feature')
    @establissement_concern = @feature.concerns.detect {|c| c.name == 'Establissement'}
    @establissement_concern.update!(klass: @establissement_klass)
    @establissement_concern.options.detect {|o| o.name == 'siret_attribute'}.update!(value: @establissement_klass.attrs.detect{|a| a.name == 'siret'})
    @establissement_concern.options.detect {|o| o.name == 'name_attribute'}.update!(value: @establissement_klass.attrs.detect{|a| a.name == 'denomination'})
    @schema.load
  end

  def perform_params(organization_association)
    {
      'klass_name' => @establissement_klass.const_absolute_name,
      'user_id' => @user.id,
      'params' => { 'where' => { organization_association => nil } },
    }
  end

  it 'matches every establissement with no organization yet' do
    establissement = D::My::Establissement.create!(denomination: 'Google France', siret: '44306184100047')
    establissement_2 = D::My::Establissement.create!(denomination: 'La Poste', siret: '35600000000048')

    organization_association = @establissement_concern.options.detect {|o| o.name == 'organization_association'}

    expect(organization_association.value).to be_nil

    @feature.update!(enabled: true)
    @schema.load
    organization_association_name = @establissement_concern.reload.options.detect {|o| o.name == 'organization_association'}.value.name

    Dynamic::Company::Worker.new.perform(perform_params(organization_association_name))

    expect(D::My::Establissement.find(establissement.id).organization.siren).to eq('443061841')
    expect(D::My::Establissement.find(establissement_2.id).organization.siren).to eq('356000000')
  end

  it 'does not touch an establissement that already has an organization' do
    establissement = D::My::Establissement.create!(denomination: 'Google France', siret: '44306184100047')

    @feature.update!(enabled: true)
    @schema.load
    organization_association_name = @establissement_concern.reload.options.detect {|o| o.name == 'organization_association'}.value.name

    organization = D::My::Organization.create!(name: 'Preset', siren: '552100554')
    D::My::Establissement.find(establissement.id).update!(organization_association_name => organization)

    Dynamic::Company::Worker.new.perform(perform_params(organization_association_name))

    expect(D::My::Establissement.find(establissement.id).organization).to eq(organization)
  end

  it 'does not let one establissement with an invalid siren block the rest of the batch' do
    establissement = D::My::Establissement.create!(denomination: 'Google France', siret: '44306184100047')
    establissement_invalid = D::My::Establissement.create!(denomination: 'Uneek', siret: '12345678900012')
    establissement_2 = D::My::Establissement.create!(denomination: 'La Poste', siret: '35600000000048')

    @feature.update!(enabled: true)
    @schema.load
    organization_association_name = @establissement_concern.reload.options.detect {|o| o.name == 'organization_association'}.value.name

    expect {
      Dynamic::Company::Worker.new.perform(perform_params(organization_association_name))
    }.to_not raise_error

    expect(D::My::Establissement.find(establissement.id).organization.siren).to eq('443061841')
    expect(D::My::Establissement.find(establissement_2.id).organization.siren).to eq('356000000')
    expect(D::My::Establissement.find(establissement_invalid.id).organization).to be_nil
  end
end
