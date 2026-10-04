describe Dynamic::Company::Feature do
  before(:each) do
    @schema = Dynamic::Schema.create!(name: 'my')

    @feature = @schema.features.find_by(name: "Dynamic::Company::Feature")
  end

  context 'establissement_klass provided but SIREN/SIRET/name mapping not done yet' do
    it 'raises and leaves the feature disabled' do
      account_klass = @schema.klasses.create!(name: 'Account', attrs_attributes: [
        {name: 'denomination', type: 'String'},
        {name: 'siret', type: 'String'},
      ])
      @feature.concerns.detect {|c| c.name == 'Establissement'}.update!(klass: account_klass)

      expect{@feature.update!(enabled: true)}.to raise_error(NoMethodError)
      expect(@feature.reload.enabled?).to be false
    end
  end

  context 'establissement_klass not provided (tenant with no existing Compte)' do
    it 'auto-creates the Establissement klass with the expected attributes' do
      @feature.update!(enabled: true)
      establissement_klass = @feature.concerns.detect {|c| c.name == 'Establissement'}.reload.klass

      expect(establissement_klass).to be_present
      expect(establissement_klass.attrs.map(&:name)).to contain_exactly('name', 'siret', 'ape', 'creation_date', 'closing_date')
      expect(establissement_klass.attachments.map(&:name)).to contain_exactly('logo')
    end

    it 'rejects a SIRET that fails the validation' do
      @feature.update!(enabled: true)
      @schema.load

      expect{D::My::Establissement.create!(name: 'Uneek', siret: '50887598600013')}.to raise_error(ActiveRecord::RecordInvalid)
      expect{D::My::Establissement.create!(name: 'Uneek', siret: '508875986000')}.to raise_error(ActiveRecord::RecordInvalid)
      expect{D::My::Establissement.create!(name: 'Uneek', siret: '508875986000UI')}.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'rejects a duplicate SIRET' do
      @feature.update!(enabled: true)
      @schema.load

      D::My::Establissement.create!(name: 'Uneek', siret: '50887598600012')
      expect{D::My::Establissement.create!(name: 'Uneek Lyon', siret: '50887598600012')}.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'rejects a creation date that is after the closing date' do
      @feature.update!(enabled: true)
      @schema.load

      expect{D::My::Establissement.create!(name: 'Uneek', creation_date: Date.new(2024, 1, 1), closing_date: Date.new(2023, 1, 1))}.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'accepts a creation date on or before the closing date' do
      @feature.update!(enabled: true)
      @schema.load

      establissement = D::My::Establissement.create!(name: 'Uneek', creation_date: Date.new(2023, 1, 1), closing_date: Date.new(2024, 1, 1))
      expect(establissement.creation_date).to eq(Date.new(2023, 1, 1))
    end

  end

  context 'establissement_klass filled' do
    before(:each) do
      @establissement_klass = @schema.klasses.create!(name: 'Establissement', attrs_attributes: [
        {name: 'denomination', type: 'String'},
        {name: 'siret', type: 'String'},
      ])
      establissement_concern = @feature.concerns.detect {|c| c.name == 'Establissement'}
      establissement_concern.update!(klass: @establissement_klass)
      establissement_concern.options.detect {|o| o.name == 'siret_attribute'}.update!(value: @establissement_klass.attrs.detect{|a| a.name == 'siret'})
      establissement_concern.options.detect {|o| o.name == 'name_attribute'}.update!(value: @establissement_klass.attrs.detect{|a| a.name == 'denomination'})
      @schema.load
      @feature.concerns.detect{ |c| c.name == 'Establissement'}.update!(klass: @establissement_klass)
    end

    it 'should create Organization klass with expected attributes' do
      @feature.update!(enabled: true)
      company_klass = @feature.concerns.detect { |c| c.name == 'Organization'}.reload.klass
      expect(company_klass.attrs.map(&:name)).to contain_exactly('name', 'siren', 'legal_category', 'creation_date', 'closing_date', 'headquarters_siret')
    end

    it 'should create the Shareholding klass with a percentage attribute' do
      @feature.update!(enabled: true)
      shareholding_klass = @feature.concerns.detect {|c| c.name == 'Shareholding'}.reload.klass
      expect(shareholding_klass.attrs.map(&:name)).to contain_exactly('percentage')
    end

    it 'should create parent/subsidiary associations between Shareholding and Organization' do
      @feature.update!(enabled: true)
      company_klass = @feature.concerns.detect {|c| c.name == 'Organization'}.reload.klass
      shareholding_klass = @feature.concerns.detect {|c| c.name == 'Shareholding'}.reload.klass

      expect(shareholding_klass.associations.detect {|a| a.name == 'parent'}.target_klass).to eq(company_klass)
      expect(shareholding_klass.associations.detect {|a| a.name == 'subsidiary'}.target_klass).to eq(company_klass)
      expect(company_klass.associations.detect {|a| a.name == 'shareholdings'}.target_klass).to eq(shareholding_klass)
      expect(company_klass.associations.detect {|a| a.name == 'shareholders'}.target_klass).to eq(shareholding_klass)
    end

    it 'should create establissements/company associations between the table Organization and Establissement' do
      @feature.update!(enabled: true)
      company_klass = @feature.concerns.detect {|c| c.name == 'Organization'}.reload.klass
      expect(company_klass.associations.detect {|a| a.name == 'establissements'}.target_klass).to eq(@establissement_klass)
      expect(@establissement_klass.reload.associations.detect {|a| a.name == 'organization'}.target_klass).to eq(company_klass)
    end

    it 'should support recording a qualified (percentage) stake between two companies' do
      @feature.update!(enabled: true)
      @schema.load
      parent = D::My::Organization.create!(name: 'Groupe')
      subsidiary = D::My::Organization.create!(name: 'Filiale')
      D::My::Shareholding.create!(parent: parent, subsidiary: subsidiary, percentage: 20)

      expect(parent.shareholdings.reload.first.subsidiary).to eq(subsidiary)
      expect(parent.shareholdings.reload.first.percentage).to eq(20)
      expect(subsidiary.shareholders.reload.first.parent).to eq(parent)
    end

    it 'should reject an invalid SIREN' do
      @feature.update!(enabled: true)
      @schema.load

      expect{D::My::Organization.create!(name: 'Acme', siren: '123456789')}.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'should accept a valid SIREN and strip punctuation' do
      @feature.update!(enabled: true)
      @schema.load
      company = D::My::Organization.create!(name: 'Uneek', siren: '552 100 554')

      expect(company.siren).to eq('552100554')
    end

    it "should not accept a company with a siren that already exist" do
      @feature.update!(enabled: true)
      @schema.load

      company_1 = D::My::Organization.create!(name: 'Acme', siren: '552100554')
      expect{D::My::Organization.create!(name: 'Acme Lyon', siren: '552100554')}.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'rejects an Organization creation date that is after its closing date' do
      @feature.update!(enabled: true)
      @schema.load

      expect{D::My::Organization.create!(name: 'Acme', creation_date: Date.new(2024, 1, 1), closing_date: Date.new(2023, 1, 1))}.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  context 'Establissement klass not provided (feature auto-creates it) every attribute, attachment and association is wired correctly' do
    before(:each) do
      @feature.update!(enabled: true)
      @schema.load
    end

    it 'creates every expected attribute on Establissement, each self-referenced on its own concern option' do
      establissement_concern = @feature.concerns.detect {|c| c.name == 'Establissement'}.reload
      establissement_klass = establissement_concern.klass

      expect(establissement_klass.attrs.map(&:name)).to contain_exactly('name', 'siret', 'ape', 'creation_date', 'closing_date')

      {
        'name_attribute' => 'name', 'siret_attribute' => 'siret', 'ape_attribute' => 'ape',
        'creation_date_attribute' => 'creation_date', 'closing_date_attribute' => 'closing_date',
      }.each do |option_name, attr_name|
        option = establissement_concern.options.detect {|o| o.name == option_name}
        expect(option.value).to eq(establissement_klass.attrs.detect {|a| a.name == attr_name})
      end
    end

    it 'creates the logo attachment on Establissement, self-referenced on its own concern option' do
      establissement_concern = @feature.concerns.detect {|c| c.name == 'Establissement'}.reload
      establissement_klass = establissement_concern.klass

      expect(establissement_klass.attachments.map(&:name)).to contain_exactly('logo')
      option = establissement_concern.options.detect {|o| o.name == 'logo_attachment'}
      expect(option.value).to eq(establissement_klass.attachments.detect {|a| a.name == 'logo'})
    end

    it 'creates every expected attribute on Organization, each self-referenced on its own concern option' do
      company_concern = @feature.concerns.detect {|c| c.name == 'Organization'}.reload
      company_klass = company_concern.klass

      expect(company_klass.attrs.map(&:name)).to contain_exactly('name', 'siren', 'legal_category', 'creation_date', 'closing_date', 'headquarters_siret')

      {
        'name_attribute' => 'name', 'siren_attribute' => 'siren', 'legal_category_attribute' => 'legal_category',
        'creation_date_attribute' => 'creation_date', 'closing_date_attribute' => 'closing_date',
      }.each do |option_name, attr_name|
        option = company_concern.options.detect {|o| o.name == option_name}
        expect(option.value).to eq(company_klass.attrs.detect {|a| a.name == attr_name})
      end
    end

    it 'creates the logo attachment on Organization, self-referenced on its own concern option' do
      company_concern = @feature.concerns.detect {|c| c.name == 'Organization'}.reload
      company_klass = company_concern.klass

      expect(company_klass.attachments.map(&:name)).to contain_exactly('logo')
      option = company_concern.options.detect {|o| o.name == 'logo_attachment'}
      expect(option.value).to eq(company_klass.attachments.detect {|a| a.name == 'logo'})
    end

    it 'creates the percentage attribute on Shareholding, self-referenced on its own concern option' do
      shareholding_concern = @feature.concerns.detect {|c| c.name == 'Shareholding'}.reload
      shareholding_klass = shareholding_concern.klass

      expect(shareholding_klass.attrs.map(&:name)).to contain_exactly('percentage')
      option = shareholding_concern.options.detect {|o| o.name == 'percentage_attribute'}
      expect(option.value).to eq(shareholding_klass.attrs.detect {|a| a.name == 'percentage'})
    end

    it 'links Establissement and Organization together, self-referenced on both concerns' do
      establissement_concern = @feature.concerns.detect {|c| c.name == 'Establissement'}.reload
      company_concern = @feature.concerns.detect {|c| c.name == 'Organization'}.reload
      establissement_klass = establissement_concern.klass
      company_klass = company_concern.klass

      company_assoc = company_klass.associations.detect {|a| a.name == 'establissements'}
      establissement_assoc = establissement_klass.associations.detect {|a| a.name == 'organization'}

      expect(company_assoc.target_klass).to eq(establissement_klass)
      expect(establissement_assoc.target_klass).to eq(company_klass)
      expect(company_assoc.inverse_of).to eq(establissement_assoc)
      expect(establissement_assoc.inverse_of).to eq(company_assoc)

      expect(company_concern.options.detect {|o| o.name == 'establissement_association'}.value).to eq(company_assoc)
      expect(establissement_concern.options.detect {|o| o.name == 'organization_association'}.value).to eq(establissement_assoc)
    end

    it 'links Organization and Shareholding together (both directions), self-referenced on both concerns' do
      company_concern = @feature.concerns.detect {|c| c.name == 'Organization'}.reload
      shareholding_concern = @feature.concerns.detect {|c| c.name == 'Shareholding'}.reload
      company_klass = company_concern.klass
      shareholding_klass = shareholding_concern.klass

      shareholdings_assoc = company_klass.associations.detect {|a| a.name == 'shareholdings'}
      shareholders_assoc = company_klass.associations.detect {|a| a.name == 'shareholders'}
      parent_assoc = shareholding_klass.associations.detect {|a| a.name == 'parent'}
      subsidiary_assoc = shareholding_klass.associations.detect {|a| a.name == 'subsidiary'}

      expect(shareholdings_assoc.target_klass).to eq(shareholding_klass)
      expect(shareholders_assoc.target_klass).to eq(shareholding_klass)
      expect(parent_assoc.target_klass).to eq(company_klass)
      expect(subsidiary_assoc.target_klass).to eq(company_klass)
      expect(shareholdings_assoc.inverse_of).to eq(parent_assoc)
      expect(shareholders_assoc.inverse_of).to eq(subsidiary_assoc)

      expect(company_concern.options.detect {|o| o.name == 'shareholdings_association'}.value).to eq(shareholdings_assoc)
      expect(company_concern.options.detect {|o| o.name == 'shareholders_association'}.value).to eq(shareholders_assoc)
      expect(shareholding_concern.options.detect {|o| o.name == 'parent_association'}.value).to eq(parent_assoc)
      expect(shareholding_concern.options.detect {|o| o.name == 'subsidiary_association'}.value).to eq(subsidiary_assoc)
    end
  end

  context 'match_comptes_after_enable only runs the batch backfill once', sidekiq: false do
    it 'does not re-run on a later enable cycle' do
      user = User.create!(last_name: 'albert', email: 'albert@mousquetaire.fr', login: 'albert@mousquetaire.fr')
      User.current = user

      establissement_klass = @schema.klasses.create!(name: 'Establissement', attrs_attributes: [
        {name: 'denomination', type: 'String'},
        {name: 'siret', type: 'String'},
      ])
      establissement_concern = @feature.concerns.detect {|c| c.name == 'Establissement'}
      establissement_concern.update!(klass: establissement_klass)
      establissement_concern.options.detect {|o| o.name == 'siret_attribute'}.update!(value: establissement_klass.attrs.detect{|a| a.name == 'siret'})
      establissement_concern.options.detect {|o| o.name == 'name_attribute'}.update!(value: establissement_klass.attrs.detect{|a| a.name == 'denomination'})
      @schema.load

      account = D::My::Establissement.create!(denomination: 'Uneek', siret: '50887598600012')
      Sidekiq::Testing.inline! do
        @feature.update!(enabled: true)
      end
      @schema.load

      company = D::My::Establissement.find(account.id).organization
      company.update!(siren: '784438129')

      @feature.update!(enabled: false)
      Sidekiq::Testing.inline! do
        @feature.update!(enabled: true)
      end
      @schema.load

      expect(D::My::Organization.find(company.id).siren).to eq('784438129')
    end
  end

end
