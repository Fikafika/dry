require "support/active_storage_helper"

describe Dynamic::Company::Establissement do
  include RSpec::ActiveStorage::Helper

  before(:each) do
    @schema = Dynamic::Schema.create!(name: 'my')

    @feature = @schema.features.find_by(name: "Dynamic::Company::Feature")
  end

  context 'once the SIREN/SIRET/name mapping is filled in, creating an Establissement matches or creates its Organization automatically' do
    before(:each) do
      @establissement_klass = @schema.klasses.create!(name: 'Establissement',
        attrs_attributes: [
          {name: 'denomination', type: 'String'},
          {name: 'siret', type: 'String'},
        ],
        attachments_attributes: [
          {name: 'logo', type: 'HasOne'},
        ],
      )
      establissement_concern = @feature.concerns.detect {|c| c.name == 'Establissement'}
      establissement_concern.update!(klass: @establissement_klass)
      establissement_concern.options.detect {|o| o.name == 'siret_attribute'}.update!(value: @establissement_klass.attrs.detect{|a| a.name == 'siret'})
      establissement_concern.options.detect {|o| o.name == 'name_attribute'}.update!(value: @establissement_klass.attrs.detect{|a| a.name == 'denomination'})
      establissement_concern.options.detect {|o| o.name == 'logo_attachment'}.update!(value: @establissement_klass.attachments.detect{|a| a.name == 'logo'})
      @feature.update!(enabled: true)
      @schema.load
    end

    it 'creates a new Organization deriving its SIREN from the SIRET when nothing matches yet' do
      establissement = D::My::Establissement.create!(denomination: 'Uneek', siret: '50887598600012')
      company = establissement.reload.organization

      expect(company).to be_present
      expect(company.siren).to eq('508875986') # first 9 digits of the SIRET
      expect(company.name).to eq('Uneek')
    end

    it 'creates a new Organization from the name alone when the Establissement has neither SIREN nor SIRET' do
      establissement = D::My::Establissement.create!(denomination: 'Uneek')

      expect(establissement.reload.organization).to be_present
      expect(establissement.organization.name).to eq('Uneek')
    end

    it 'attaches to the existing Organization matched by SIREN instead of creating a duplicate' do
      company = D::My::Organization.create!(name: 'Uneek', siren: '508875986')
      establissement = D::My::Establissement.create!(denomination: 'Uneek', siret: '50887598600012')

      expect(establissement.reload.organization).to eq(company)
      expect(D::My::Organization.count).to eq(1)
    end

    it "backfills the matched Organization's name when it was blank" do
      company = D::My::Organization.create!(siren: '508875986') # no name yet
      establissement = D::My::Establissement.create!(denomination: 'Uneek', siret: '50887598600012')

      expect(establissement.reload.organization).to eq(company)
      expect(company.reload.name).to eq('Uneek')
    end

    it "never overwrites the matched Organization's existing name" do
      company = D::My::Organization.create!(name: 'Uneek Historique', siren: '508875986')
      establissement = D::My::Establissement.create!(denomination: 'Uneek', siret: '50887598600012')

      expect(establissement.reload.organization).to eq(company)
      expect(company.reload.name).to eq('Uneek Historique')
    end

    it 'falls back to a SIREN-less Organization matched by name, and backfills its SIREN' do
      company = D::My::Organization.create!(name: 'Uneek') # no siren yet
      establissement = D::My::Establissement.create!(denomination: 'Uneek', siret: '50887598600012')

      expect(establissement.reload.organization).to eq(company)
      expect(company.reload.siren).to eq('508875986')
      expect(D::My::Organization.count).to eq(1)
    end

    it 'never merges into an Organization that already has a different, confirmed SIREN, even if the name matches' do
      other_company = D::My::Organization.create!(name: 'Uneek', siren: '552100554')
      establissement = D::My::Establissement.create!(denomination: 'Uneek', siret: '50887598600012')

      expect(establissement.reload.organization).to_not eq(other_company)
      expect(establissement.organization.siren).to eq('508875986')
      expect(D::My::Organization.count).to eq(2)
    end

    it 'leaves the Establishement unattached when it has neither an identifier nor a name' do
      establissement = D::My::Establissement.create!

      expect(establissement.reload.organization).to be_nil
    end

    it 'copies the logo from the Establissement onto the newly matched Organization' do
      establissement = D::My::Establissement.new(denomination: 'Uneek', siret: '50887598600012')
      attach_fixture_file(establissement.logo, 'file.jpg')
      establissement.save!

      company = establissement.reload.organization
      expect(company.logo).to be_attached
    end
  end

  context 'batch backfill of establissements created before the mapping was filled in', sidekiq: false do
    before(:each) do
      @user = User.create!(last_name: 'albert', email: 'albert@mousquetaire.fr', login: 'albert@mousquetaire.fr')
      User.current = @user

      @establissement_klass = @schema.klasses.create!(name: 'Establissement', attrs_attributes: [
        {name: 'denomination', type: 'String'},
        {name: 'siret', type: 'String'},
      ])
      establissement_concern = @feature.concerns.detect {|c| c.name == 'Establissement'}
      establissement_concern.update!(klass: @establissement_klass)
      establissement_concern.options.detect {|o| o.name == 'siret_attribute'}.update!(value: @establissement_klass.attrs.detect{|a| a.name == 'siret'})
      establissement_concern.options.detect {|o| o.name == 'name_attribute'}.update!(value: @establissement_klass.attrs.detect{|a| a.name == 'denomination'})
      @schema.load
    end

    it 'matches every pre-existing establissement once the feature is enabled' do
      establissement = D::My::Establissement.create!(denomination: 'Google France', siret: '44306184100047')
      establissement_2 = D::My::Establissement.create!(denomination: 'SNCF Voyageurs', siret: '51903758400011')
      establissement_3 = D::My::Establissement.create!(denomination: 'La Poste', siret: '35600000000048')

      Sidekiq::Testing.inline! do
        @feature.update!(enabled: true)
      end
      @schema.load

      company = D::My::Establissement.find(establissement.id).organization
      company_2 = D::My::Establissement.find(establissement_2.id).organization
      company_3 = D::My::Establissement.find(establissement_3.id).organization

      expect(company).to be_present
      expect(company.siren).to eq('443061841')
      expect(company.name).to eq('Google France')

      expect(company_2).to be_present
      expect(company_2.siren).to eq('519037584')
      expect(company_2.name).to eq('SNCF Voyageurs')

      expect(company_3).to be_present
      expect(company_3.siren).to eq('356000000')
      expect(company_3.name).to eq('La Poste')
    end

    it 'reuses the existing company when another establissement belongs to the same company' do
      D::My::Establissement.create!(denomination: 'SNCF Voyageurs', siret: '51903758400011')
      establissement_2 = D::My::Establissement.create!(denomination: 'Google France', siret: '44306184100047')
      establissement_3 = D::My::Establissement.create!(denomination: 'Google France', siret: '44306184100099')

      Sidekiq::Testing.inline! do
        @feature.update!(enabled: true)
      end
      @schema.load

      company_2 = D::My::Establissement.find(establissement_2.id).organization
      company_3 = D::My::Establissement.find(establissement_3.id).organization

      expect(company_2).to eq(company_3)
      expect(D::My::Organization.count).to eq(2)
    end

    it 'does not create a company when the establissement has neither a denomination nor a siret' do
      establissement = D::My::Establissement.create!(denomination: nil, siret: nil)

      Sidekiq::Testing.inline! do
        @feature.update!(enabled: true)
      end
      @schema.load

      company = D::My::Establissement.find(establissement.id).organization

      expect(company).to be_nil
      expect(D::My::Organization.count).to eq(0)
    end
  end

  context 'change a value in the establissement klass, after an Establissement already exists', sidekiq: false do
    before(:each) do
      @user = User.create!(last_name: 'albert', email: 'albert@mousquetaire.fr', login: 'albert@mousquetaire.fr')
      User.current = @user

      @establissement_klass = @schema.klasses.create!(
        name: 'Establissement',
        attrs_attributes: [
          {name: 'denomination', type: 'String'},
          {name: 'siret', type: 'String'},
          {name: 'founded_on', type: 'Date'},
        ]
      )

      establissement_concern = @feature.concerns.detect {|c| c.name == 'Establissement'}
      establissement_concern.update!(klass: @establissement_klass)
      establissement_concern.options.detect {|o| o.name == 'siret_attribute'}.update!(value: @establissement_klass.attrs.detect{|a| a.name == 'siret'})
      establissement_concern.options.detect {|o| o.name == 'name_attribute'}.update!(value: @establissement_klass.attrs.detect{|a| a.name == 'denomination'})
      establissement_concern.options.detect {|o| o.name == 'creation_date_attribute'}.update!(value: @establissement_klass.attrs.detect{|a| a.name == 'founded_on'})
      @schema.load

      @establissement = D::My::Establissement.create!(denomination: 'Acme', siret: '87785142800020', founded_on: Date.new(2005, 6, 1))
      @establissement_2 = D::My::Establissement.create!(denomination: 'Uneek')
      Sidekiq::Testing.inline! do
        @feature.update!(enabled: true)
      end
      @schema.load

      @company = D::My::Establissement.find(@establissement.id).organization
      @company_2 = D::My::Establissement.find(@establissement_2.id).organization
      expect(@company).to be_present
    end

    it 'does not update the Organization when founded_on changes afterward' do
      D::My::Establissement.find(@establissement.id).update!(founded_on: Date.new(1998, 1, 1))
      expect(D::My::Organization.find(@company.id).creation_date).to eq(Date.new(2005, 6, 1))
    end

    it 'rematch to another company when siret changes afterward' do
      D::My::Establissement.find(@establissement.id).update!(siret: '50887598600012')
      expect(D::My::Organization.find(@company.id).siren).to eq('877851428')
      expect(D::My::Establissement.find(@establissement.id).organization.siren).to eq('508875986')
    end

    it 'rematch to another company when only denomination changes afterward and the siret is nil' do
      D::My::Establissement.find(@establissement.id).update!(denomination: 'Acme Lyon')
      expect(D::My::Organization.find(@company.id).name).to eq('Acme')

      D::My::Establissement.find(@establissement_2.id).update!(denomination: 'Uneek Nantes')
      expect(D::My::Organization.find(@company_2.id).name).to eq('Uneek')
      expect(D::My::Establissement.find(@establissement_2.id).organization.name).to eq('Uneek Nantes')
    end
  end
end
