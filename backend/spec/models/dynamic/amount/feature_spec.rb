describe Dynamic::Amount::Feature, elasticsearch: false, sidekiq: false do
  before(:each) do
    User.current = User.create!(last_name: 'albert', email: 'albert@mousquetaire.fr', login: 'albert@mousquetaire.fr')
    @schema = Dynamic::Schema.create!(name: 'my')
    @feature = @schema.features.find_by(name: 'Dynamic::Amount::Feature')

    Dynamic::Schema.load(@schema.name)
  end

  after(:each) do
    @schema.unload
  end

  it 'should raise when dependant features are disabled' do
    expect{
      @feature.update!(enabled: true)
    }.to raise_error{ActiveRecord::RecordInvalid}
  end

  context 'when dependant features are enabled' do
    before(:each) do
      @schema.features.find_by(name: 'Dynamic::Country::Feature').update!(enabled: true)
      @schema.features.find_by(name: 'Dynamic::Currency::Feature').update!(enabled: true)
    end

    context 'Amount klass' do
      before(:each) do
        @feature.update!(enabled: true)
      end

      it 'should create an association with currency' do
        klass = @schema.klasses.detect {|k| k.name == 'Amount'}
        target_of_amount_associations = Dynamic::Schema::Association::Base.where(owner_klass: klass).all.map {|a| a.target_klass.name}
        expect(target_of_amount_associations).to contain_exactly('Currency')
      end

      it 'should update "new" form to implictly set currency' do
        form = Dynamic::Form.includes(:elements).with_action([:input]).where(klass_name: 'D::My::Amount', default: true).first
        element = form.elements.detect {|e| e.attribute_name == 'currency'}
        expect(element.editor).to eq('hidden')
        expect(element.default_value_record).to eq(D::My::Currency.find_by(iso_code: 'EUR'))
      end

    end

    context 'Vat klass' do
      before(:each) do
        @feature.update!(enabled: true)
      end

      xit 'should create percent presence validation' do
        klass = @schema.klasses.detect {|k| k.name == 'Vat'}
        expect(klass.validations.detect {|v| v.name == 'percent_presence'}).to be
      end

    end

  end

end
