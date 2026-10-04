describe Dynamic::Currency::Feature, elasticsearch: false, sidekiq: false do
  before(:each) do
    User.current = User.create!(last_name: 'albert', email: 'albert@mousquetaire.fr', login: 'albert@mousquetaire.fr')
    @schema = Dynamic::Schema.create!(name: 'my')
    @feature = @schema.features.find_by(name: 'Dynamic::Currency::Feature')
    @schema.load
  end

  it 'should raise if Country feature is disabled' do
    expect{@feature.update!(enabled: true)}.to raise_error{ActiveRecord::RecordInvalid}
    expect(@feature.errors.details[:enabled]).to contain_exactly(
      include(
        error: :dependent,
        name: @schema.features.find_by(name: 'Dynamic::Country::Feature').human_name,
      )
    )
  end

  context 'Country feature enabled' do
    before(:each) do
      @schema.features.find_by(name: 'Dynamic::Country::Feature').update!(enabled: true)
    end

    it 'should create layout and forms' do
      expect{
        @feature.update!(enabled: true)
      }.to change{
        Dynamic::Layout.where(klass_name: 'D::My::Currency').count
      }.by(4).and change{
        Dynamic::Form.where(klass_name: 'D::My::Currency').count
      }.by(3)
    end

    it 'should create attributes' do
      expect{
        @feature.update!(enabled: true)
      }.to change{
        Dynamic::Schema::Klass.find_by(name: 'Currency')&.attrs&.count || 0
      }.from(0).to(13)
    end

    context 'dependency with country feature' do
      before(:each) do
        @feature.update!(enabled: true)
      end

      it 'should enable it' do
        country_feature = @schema.features.find_by(name: 'Dynamic::Country::Feature')
        expect(country_feature.enabled).to be true
      end

      it 'should create associations for Country and Currency' do
        expect(@schema.klasses.find_by(name: 'Currency').associations.first.name).to eq('countries')
        expect(@schema.klasses.find_by(name: 'Country').associations.last.name).to eq('currencies')
      end

    end

    xcontext 'record creation', sidekiq: true do
      before(:each) do
        @schema.features.find_by(name: 'Dynamic::Country::Feature').update!(enabled: true)  # FIXME wait for jobs' batch to complete
      end

      it 'should create timezones and not duplicate countries' do
        @feature.update!(enabled: true)  # FIXME wait for jobs' batch to complete
        expect(D::My::Currency.count).to eq(Money::Currency.all.count)
        expect(D::My::Country.count).to eq(ISO3166::Country.all.count)
      end
    end

  end

end