describe Dynamic::Transaction::Feature, elasticsearch: false, sidekiq: false do
  before(:each) do
    @schema = Dynamic::Schema.create!(name: 'my')
    @feature = @schema.features.find_by(name: 'Dynamic::Transaction::Feature')

    @contact = @schema.klasses.create!(name: 'Contact', attrs_attributes: [name: 'name', type: 'String'])
    @account = @schema.klasses.create!(name: 'Account', attrs_attributes: [name: 'name', type: 'String'])

    @feature.options.detect {|f| f.name == 'contact_klass'}.update!(value: @contact)

    User.current = User.create!(last_name: 'albert', email: 'albert@mousquetaire.fr', login: 'albert@mousquetaire.fr')

    country_feature = @schema.features.find_by(name: 'Dynamic::Country::Feature')
    country_feature.options.detect {|o| o.name == 'update_countries'}.update!(value: false)
    country_feature.update!(enabled: true)

    currency_feature = @schema.features.find_by(name: 'Dynamic::Currency::Feature')
    currency_feature.options.detect {|o| o.name == 'update_currencies'}.update!(value: false)
    currency_feature.update!(enabled: true)

    feature_product = @schema.features.find_by(name: 'Dynamic::Product::Feature')
    feature_product.options.detect {|f| f.name == 'account_klass'}.update!(value: @account)
    feature_product.update!(enabled: true)

    @schema.features.find_by(name: 'Dynamic::Amount::Feature').update!(enabled: true)
  end

  context 'when enabled' do
    before(:each) do
      @feature.update!(enabled: true)
    end

    it 'should create associations' do
      @schema.klasses.reload

      transaction = @schema.klasses.detect {|k| k.name == 'Transaction'}
      transaction_line = @schema.klasses.detect {|k| k.name == 'TransactionLine'}
      quote = @schema.klasses.detect {|k| k.name == 'Quote'}
      order = @schema.klasses.detect {|k| k.name == 'Order'}
      invoice = @schema.klasses.detect {|k| k.name == 'Invoice'}

      expect(Dynamic::Schema::Association::HasMany.exists?(name: 'sale_transactions', owner_klass: @account, target_klass: transaction)).to be true
      expect(Dynamic::Schema::Association::BelongsTo.exists?(name: 'seller_company', owner_klass: transaction, target_klass: @account)).to be true
      expect(Dynamic::Schema::Association::HasMany.exists?(name: 'purchase_transactions', owner_klass: @account, target_klass: transaction)).to be true
      expect(Dynamic::Schema::Association::BelongsTo.exists?(name: 'buyer_company', owner_klass: transaction, target_klass: @account)).to be true
      expect(Dynamic::Schema::Association::HasMany.exists?(name: 'transaction_lines', owner_klass: transaction, target_klass: transaction_line)).to be true
      expect(Dynamic::Schema::Association::BelongsTo.exists?(name: 'owner_transaction', owner_klass: transaction_line, target_klass: transaction)).to be true
      expect(Dynamic::Schema::Association::HasMany.exists?(name: 'quote_orders', owner_klass: quote, target_klass: order)).to be true
      expect(Dynamic::Schema::Association::HasMany.exists?(name: 'quotes', owner_klass: order, target_klass: quote)).to be true
      expect(Dynamic::Schema::Association::HasMany.exists?(name: 'invoices', owner_klass: order, target_klass: invoice)).to be true
      expect(Dynamic::Schema::Association::HasMany.exists?(name: 'invoice_orders', owner_klass: invoice, target_klass: order)).to be true
    end

    it 'should create a VatComputable concern for Article klass' do
      feature = @schema.features.detect {|f| f.name == 'Dynamic::Amount::Feature'}
      klasses_for_concern = feature.concerns.select {|c| c.name == 'VatComputable'}.map {|c| c.klass.name}
      expect(klasses_for_concern).to contain_exactly('Article', 'ProductPropertyValue')
    end

    it 'should add name_attribute to Transaction and TransactionLine' do
      transaction = @schema.klasses.detect {|k| k.name == 'Transaction'}
      transaction_line = @schema.klasses.detect {|k| k.name == 'TransactionLine'}
      expect(transaction.name_attribute).to eq(transaction.attrs.detect {|a| a.name == 'label'})
      expect(transaction_line.name_attribute).to eq(transaction_line.attrs.detect {|a| a.name == 'label'})
    end

    it 'should add options_for_indexed_json to TransactionLine' do
      transaction_line = @schema.klasses.detect {|k| k.name == 'TransactionLine'}
      expect(transaction_line.options_for_indexed_json['include']).to include(
        'parent' => {'only' => ['id', 'label', 'type', 'created_at', 'updated_at', 'deleted_at']},
        'owner_transaction' => {'only' => ['id', 'label', 'type', 'created_at', 'updated_at', 'deleted_at']},
      )
    end

    context 'forms' do

      it 'should add step editor to conver_until elements for Quote and Order' do
        actions = [Dynamic::Form::ACTIONS_TO_I[:new], Dynamic::Form::ACTIONS_TO_I[:edit]]
        editors = Dynamic::Form.includes(:elements).where(actions: actions, klass_name: ['D::My::Quote', 'D::My::Order'], elements: {attribute_name: 'convert_until'}).pluck(:editor)
        expect(editors.uniq).to contain_exactly('step')
      end

      it 'should remove convert_until element for Invoice' do
        actions = [Dynamic::Form::ACTIONS_TO_I[:new], Dynamic::Form::ACTIONS_TO_I[:edit]]
        convert_until_element_count = Dynamic::Form.includes(:elements).where(actions: actions, klass_name: 'D::My::Invoice', elements: {attribute_name: 'convert_until'}).count
        expect(convert_until_element_count).to eq(0)
      end

    end

    context 'disabling' do
      before(:each) do
        @feature.update!(enabled: false)
      end

      it 'should not raise when enabling once more' do
        expect{@feature.update!(enabled: true)}.to_not raise_error
      end
    end

  end
end
