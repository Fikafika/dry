describe Dynamic::Timezone::Feature, elasticsearch: false, sidekiq: false do
  before(:each) do
    @user = User.create!(last_name: 'albert', email: 'albert@mousquetaire.fr', login: 'albert@mousquetaire.fr')
    User.current = @user

    @schema = Dynamic::Schema.create!(name: 'my')
    @feature = @schema.features.find_by(name: 'Dynamic::Timezone::Feature')
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
        Dynamic::Layout.where(klass_name: 'D::My::Timezone').count
      }.by(3).and change{
        Dynamic::Form.where(klass_name: 'D::My::Timezone').count
      }.by(2)
    end

    it 'should create klass, associations and attributes' do
      expect{
        @feature.update!(enabled: true)
      }.to change{
        Dynamic::Schema::Klass.where(name: 'Timezone').count
      }.by(1).and change{
        Dynamic::Schema::Klass.find_by(name: 'Timezone')&.associations&.count || 0
      }.by(1).and change{
        Dynamic::Schema::Klass.find_by(name: 'Timezone')&.attrs&.count || 0
      }.by(4)
    end

    it 'should create associations timezones for Country' do
      expect{
        @feature.update!(enabled: true)
      }.to change{
        Dynamic::Schema::Association::HasMany.where(name: 'timezones').count
      }.by(1)
    end
  end

  xcontext 'record creation', sidekiq: true do
    before(:each) do
      @schema.features.find_by(name: 'Dynamic::Country::Feature').update!(enabled: true)  # FIXME wait for jobs' batch to complete
    end

    it 'should create timezones and not duplicate countries' do
      @feature.update!(enabled: true)  # FIXME wait for jobs' batch to complete
      expect(D::My::Timezone.count).to eq(::TZInfo::Country.all.map{|c| c.zone_info.map(&:identifier)}.flatten.uniq.count)
      expect(D::My::Country.where(iso_code_a2: 'FR').count).to eq(1)
    end
  end
end