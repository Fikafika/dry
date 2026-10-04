describe Dynamic::Schema::Feature, elasticsearch: false, sidekiq: false do
  before(:each) do
    @schema = Dynamic::Schema.create!(name: 'my')
    @schema.klasses.create!(id: '44e90d6f-c4c4-4fa9-8cb8-0128634758db', name: 'MyKlass')
    @feature = @schema.features.create!(name: 'MyFeature')
  end

  describe 'as_deep_json' do
    it 'options that contains klasses in values should not be deserialized' do
      @feature.options.create!(name: 'klass', coder_type: 'Dynamic::Schema::Option::Coder::Klass', value: '44e90d6f-c4c4-4fa9-8cb8-0128634758db', type: 'String')
      expect(@feature.as_deep_json(include: {options: {only: ['value']}}, secure: false)['options']).to eq [
        {'value' => '44e90d6f-c4c4-4fa9-8cb8-0128634758db'}
      ]
    end
  end
end
