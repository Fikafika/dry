describe Dynamic::Company::Organization do
  before(:each) do
      @schema = Dynamic::Schema.create!(name: 'my')

      @feature = @schema.features.find_by(name: 'Dynamic::Company::Feature')
  end

  context 'rematching establissements when their company siren changes' do
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

        @establissement = D::My::Establissement.create!(denomination: 'Acme', siret: '87785142800020')
        @feature.update!(enabled: true)
        @schema.load

        @company = D::My::Establissement.find(@establissement.id).organization
        expect(@company).to be_present
        expect(@company.siren).to eq('877851428')
    end

    it 'disassociates and rematches the establissement to a different Organization when the Organization siren changes' do
      old_company_id = @company.id
      D::My::Organization.find(@company.id).update!(siren: '508875986')

      establissement = D::My::Establissement.find(@establissement.id)
      new_company = establissement.organization

      expect(new_company).to be_present
      expect(new_company.id).to_not eq(old_company_id)
      expect(new_company.siren).to eq('877851428')
    end

    it 'rematches every establissement associated with the Organization, not just one' do
      establissement_2 = D::My::Establissement.create!(denomination: 'Acme Lyon', siret: '87785142800004')
      expect(D::My::Establissement.find(establissement_2.id).organization).to eq(@company)

      D::My::Organization.find(@company.id).update!(siren: '508875986')

      company_1 = D::My::Establissement.find(@establissement.id).organization
      company_2 = D::My::Establissement.find(establissement_2.id).organization

      expect(company_1).to eq(company_2)
      expect(company_1.siren).to eq('877851428')
    end

    it 'does not touch the establissement when something other than siren changes on the Organization' do
      D::My::Organization.find(@company.id).update!(name: 'Acme Renamed')

      expect(D::My::Establissement.find(@establissement.id).organization.id).to eq(@company.id)
    end

    it 'merges into an existing siren-less Organization matched by name, rather than creating a new one' do
      other_company = D::My::Organization.create!(name: 'Acme')

      old_company_id = @company.id
      D::My::Organization.find(@company.id).update!(siren: '508875986')

      establissement = D::My::Establissement.find(@establissement.id)
      new_company = establissement.organization

      expect(new_company).to eq(other_company)
      expect(new_company.id).to_not eq(old_company_id)
      expect(new_company.reload.siren).to eq('877851428')
    end

    it 'leaves the old Organization in place, without any establissements, rather than deleting it' do
      old_company_id = @company.id
      D::My::Organization.find(@company.id).update!(siren: '508875986')

      old_company = D::My::Organization.find(old_company_id)
      expect(old_company).to be_present
      expect(old_company.establissements.reload).to be_empty
    end
  end

  context 'matching two establissements into the same Organization via name-fallback' do
    before(:each) do
        @establissement_klass = @schema.klasses.create!(name: 'Establissement', attrs_attributes: [
            {name: 'denomination', type: 'String'},
            {name: 'siret', type: 'String'},
        ])
        establissement_concern = @feature.concerns.detect {|c| c.name == 'Establissement'}
        establissement_concern.update!(klass: @establissement_klass)
        establissement_concern.options.detect {|o| o.name == 'siret_attribute'}.update!(value: @establissement_klass.attrs.detect{|a| a.name == 'siret'})
        establissement_concern.options.detect {|o| o.name == 'name_attribute'}.update!(value: @establissement_klass.attrs.detect{|a| a.name == 'denomination'})
        @feature.update!(enabled: true)
        @schema.load
    end

    it 'keeps both establissements together after a mid-match siren backfill triggers a cascade' do
        establissement_a = D::My::Establissement.create!(denomination: 'Acme')
        company_a = D::My::Establissement.find(establissement_a.id).organization
        expect(company_a).to be_present
        expect(company_a.siren).to be_blank

        establissement_b = D::My::Establissement.create!(denomination: 'Acme', siret: '87785142800020')

        company_a_after = D::My::Establissement.find(establissement_a.id).organization
        company_b_after = D::My::Establissement.find(establissement_b.id).organization

        expect(company_a_after).to eq(company_b_after)
        expect(company_a_after.siren).to eq('877851428')
    end
  end
end
