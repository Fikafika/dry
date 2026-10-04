describe Dynamic::Amount::VatComputable, elasticsearch: false, sidekiq: false do
  before(:each) do
    @schema = Dynamic::Schema.create!(name: 'my')
    @feature = @schema.features.find_by(name: 'Dynamic::Amount::Feature')

    User.current = User.create!(last_name: 'albert', email: 'albert@mousquetaire.fr', login: 'albert@mousquetaire.fr')
    @schema.features.find_by(name: 'Dynamic::Country::Feature').update!(enabled: true)
    @schema.features.find_by(name: 'Dynamic::Currency::Feature').update!(enabled: true)
    @feature.update!(enabled: true)

    vat_klass = @schema.klasses.detect {|k| k.name == 'Vat'}

    @klass = @schema.klasses.create!(name: 'Klass', attrs_attributes: [
      {type: 'Float', name: 'price'},
      {type: 'Float', name: 'price_excluding_taxes'},
      {type: 'Float', name: 'price_including_taxes'},
      {type: 'Float', name: 'taxes_amount'},
    ],
    associations_attributes: [
      {type: 'BelongsTo', name: 'vat', target_klass: vat_klass}
    ])

    ct = @feature.concern_templates.detect {|ct| ct.name == 'VatComputable'}
    concern_attrs = ct.slice('human_name_fr', 'human_name_en', 'name')
    concern_attrs.merge!(klass: @klass)
    opts_attributes = ct.options.map do |o|
      o.slice('name', 'human_name_fr', 'human_name_en', 'value', 'type', 'coder_type', 'global')
    end

    opts_attributes.detect {|o| o['name'] == 'base_amount_attribute'}.merge!(value: @klass.attrs.detect {|a| a.name == 'price'}.id)
    opts_attributes.detect {|o| o['name'] == 'vat_rate_association'}.merge!(value: @klass.associations.detect {|a| a.name == 'vat'}.id)
    opts_attributes.detect {|o| o['name'] == 'amount_excluding_vat_attribute'}.merge!(value: @klass.attrs.detect {|a| a.name == 'price_excluding_taxes'}.id)
    opts_attributes.detect {|o| o['name'] == 'amount_including_vat_attribute'}.merge!(value: @klass.attrs.detect {|a| a.name == 'price_including_taxes'}.id)
    opts_attributes.detect {|o| o['name'] == 'vat_amount_attribute'}.merge!(value: @klass.attrs.detect {|a| a.name == 'taxes_amount'}.id)

    @concern = @feature.concerns.create!(concern_attrs.merge(options_attributes: opts_attributes))

    @schema.load

    @record = D::My::Klass.create!(
      price: 100.0,
      vat_attributes: {percent: 0.33, code: 'S'},
    )
  end

  it 'should compute correctly on creation' do
    expect(@record.price_excluding_taxes).to eq(100.0)
    expect(@record.price_including_taxes).to eq(133.0)
    expect(@record.taxes_amount).to eq(33.0)
  end

  it 'should compute when changing price' do
    expect{
      @record.update!(price: 200.0)
    }.to change{
      @record.price_excluding_taxes
    }.from(100.0).to(200.0).and change{
      @record.price_including_taxes
    }.from(133.0).to(266.0).and change{
      @record.taxes_amount
    }.from(33.0).to(66.0)
  end

  it 'should compute when updating a tax (ids setter)' do
    vat = D::My::Vat.create!(percent: 0.05, code: 'S')
    expect{
      @record.update!(vat_id: vat.id)
    }.to not_change{
      @record.reload.price_excluding_taxes
    }.and change{
      @record.reload.price_including_taxes
    }.from(133.0).to(105.0).and change{
      @record.reload.taxes_amount
    }.from(33.0).to(5.0)
  end

  it 'should compute when removing a taxe' do
    expect{
      @record.update!(vat: nil)
    }.to not_change{
      @record.price_excluding_taxes
    }.and change{
      @record.price_including_taxes
    }.from(133.0).to(100.0).and change{
      @record.taxes_amount
    }.from(33.0).to(0)
  end

  it 'should remove values when setting price to nil' do
    expect{
      @record.update!(price: nil)
    }.to change{
      @record.price_excluding_taxes
    }.from(100.0).to(nil).and change{
      @record.price_including_taxes
    }.from(133.0).to(nil).and change{
      @record.taxes_amount
    }.from(33.0).to(nil)
  end

  it 'should compute correctly when percent is negative' do
    expect{
      @record.update!(vat_attributes: {percent: -0.2, code: 'S'})
    }.to change{
      @record.price_including_taxes
    }.from(133.0).to(80.0)
  end

  context 'with quantity' do
    before(:each) do
      attr = @klass.attrs.create!(name: 'quantity', type: 'Float')
      @concern.options.detect {|o| o.name == 'quantity_attribute'}.update!(value: attr)
      @schema.unload
      @schema.load
      @record = @klass.const.find(@record.id)
    end

    it 'should compute accordingly' do
      expect{
        @record.update!(quantity: 2)
      }.to change{
        @record.price_excluding_taxes
      }.from(100.0).to(200.0).and change{
        @record.price_including_taxes
      }.from(133.0).to(266.0).and change{
        @record.taxes_amount
      }.from(33.0).to(66.0)
    end
  end

end
