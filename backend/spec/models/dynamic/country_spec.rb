describe Dynamic::Country::Feature, elasticsearch: false, sidekiq: false do
  before(:each) do
    @user = User.create!(last_name: 'albert', email: 'albert@mousquetaire.fr', login: 'albert@mousquetaire.fr')
    User.current = @user
    @schema = Dynamic::Schema.create!(name: 'my')
    @feature = @schema.features.find_by(name: 'Dynamic::Country::Feature')
  end

  it 'should create layout and forms' do
     expect{
      @feature.update!(enabled: true)
    }.to change{
      Dynamic::Layout.where(klass_name: 'D::My::Country').count
    }.by(3).and change{
      Dynamic::Form.where(klass_name: 'D::My::Country').count
    }.by(2)
  end

  it 'should set options value from attributes and klass created' do
    expect{
      @feature.update!(enabled: true)
    }.to change{
      @feature.reload.options.select {|o| o.name =~ /_attribute$/ && o.value}.count
    }.from(0).to(21).and change{
      @feature.reload.options.detect{|o| o.name == 'country_klass'}.value
    }
  end

  xcontext 'records creation', sidekiq: true do
    before(:each) do
      Sidekiq::Testing.inline! do
        @feature.update!(enabled: true) # FIXME wait for jobs' batch to complete
      end
    end

    it 'should have the right amount of records with the correct attributes' do
      expect(D::My::Country.count).to eq(::ISO3166::Country.all.count)
      expect(D::My::Country.find_by(iso_code_a2: 'FR')).to have_attributes(
        number: '250',
        name_en: 'France',
        longitude: 2.213749,
        latitude: 46.227638,
        emoji_flag: '🇫🇷',
        nationality_en: 'French',
      )
    end

    xcontext 'reactivating feature', sidekiq: true do
      before(:each) do # FIXME wait for jobs' batch to complete
        @feature.update(enabled: false)
        @feature.update(enabled: true)
      end

      it 'should not create duplicates' do
        expect(D::My::Country.count).to eq(::ISO3166::Country.all.count)
      end
    end
  end

  context 'all options activated' do
    before(:each) do
      @feature.options.detect {|o| o.name == 'other_geo_coord' }.update(value: true)
      @feature.update(enabled: true)
    end

    it 'should create all attributes' do
      expect(D::My::Country.dynamic_mapping.keys & Dynamic::Country::Feature::ATTRIBUTES_BY_NAME.keys).to contain_exactly(*Dynamic::Country::Feature::ATTRIBUTES_BY_NAME.keys)
    end
  end

  context 'table option specified' do
    before(:each) do
      @small_klass = @schema.klasses.create!(name: 'small table country', table_profile: 'small')
      @feature.options.detect {|o| o.name == 'country_klass' }.update!(value: @small_klass)
    end

    it 'should raise ActiveRecord::RecordInvalid if table_profile is too small' do
      expect{
        @feature.update!(enabled: true)
      }.to change{
        @small_klass.reload.table_profile
      }.from('small').to('large')
    end

    context 'attribute option specified' do
      before(:each) do
        @attr = @small_klass.attrs.create!(name: 'my_iso_code', type: 'String')
        @feature.options.detect {|o| o.name == 'iso_code_a2_attribute'}.update(value: @attr)
      end

      it 'should not create default attribute' do
        expect{
          @feature.update!(enabled: true)
        }.to_not change{
          @small_klass.reload.attrs.detect {|a| a.name == 'iso_code_a2'}
        }.from(nil)
      end

      it 'should mapped the correct column for import' do
        @feature.update!(enabled: true)
        import =  Dynamic::Import::Setting.find_by(name: Dynamic::Country::Feature::IMPORT_NAME)
        iso_2_column = import.output.columns.detect {|c| c.position == 1}
        expect(iso_2_column.path).to contain_exactly(0, @attr.name)
      end
    end

  end

end