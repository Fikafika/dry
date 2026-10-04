require "support/with_db_cache"

describe Dynamic::Transaction::Base, elasticsearch: false, sidekiq: false, keep_schema: true do
  before(:all) do
    with_db_cache('transaction002') do
      User.current = User.create!(last_name: 'albert', email: 'albert@mousquetaire.fr', login: 'albert@mousquetaire.fr')
      @schema = Dynamic::Schema.create!(name: 'my')
      @schema.features.find_by(name: 'Dynamic::Permission::Feature').update!(enabled: false)

      feature = @schema.features.find_by(name: 'Dynamic::Transaction::Feature')

      contact = @schema.klasses.create!(name: 'Contact', attrs_attributes: [name: 'name', type: 'String'])
      account = @schema.klasses.create!(name: 'Account', attrs_attributes: [name: 'name', type: 'String'])

      feature.options.detect {|f| f.name == 'contact_klass'}.update!(value: contact)

      country_feature = @schema.features.find_by(name: 'Dynamic::Country::Feature')
      country_feature.options.detect {|o| o.name == 'update_countries'}.update!(value: false)
      country_feature.update!(enabled: true)

      currency_feature = @schema.features.find_by(name: 'Dynamic::Currency::Feature')
      currency_feature.options.detect {|o| o.name == 'update_currencies'}.update!(value: false)
      currency_feature.update!(enabled: true)

      feature_product = @schema.features.find_by(name: 'Dynamic::Product::Feature')
      feature_product.options.detect {|f| f.name == 'account_klass'}.update!(value: account)
      feature_product.update!(enabled: true)

      @schema.features.find_by(name: 'Dynamic::Amount::Feature').update!(enabled: true)

      feature.update!(enabled: true)
    end

    User.current = User.last
  end

  after(:all) do
    User.current = nil
  end

  before(:each) do
    @schema = Dynamic::Schema.find_by!(name: 'My')
    @schema.unload
    @schema.load
  end

  describe 'convert_until' do

    it 'should create next transaction' do
      expect{
        a = D::My::Quote.create(convert_until: 'order')
      }.to change{
        D::My::Order.count
      }.by(1)
    end

    it 'should create multiple next transactions' do
      expect{
        D::My::Quote.create!(convert_until: 'invoice')
      }.to change{
        D::My::Order.count
      }.by(1).and change{
        D::My::Invoice.count
      }.by(1)
    end

    it 'should associate transactions' do
      quote = D::My::Quote.create!(convert_until: 'order')
      order = D::My::Order.first
      expect(quote.quote_orders).to contain_exactly(order)
      expect(order.quotes).to contain_exactly(quote)
    end

    it 'should duplicate transaction lines' do
      quote = D::My::Quote.create!(
        label: 'Milk Pack #123',
        transaction_lines_attributes: [
          {label: 'Milk bottle', unit: 'liter', invoiced_quantity: 4}
        ]
      )

      expect{
        quote.update!(convert_until: 'order')
      }.to change{
        D::My::TransactionLine.count
      }.by(1)
    end

    it 'should duplicate transaction lines recursively' do
      quote = D::My::Quote.create!(
        label: 'Grocery bag #123',
        transaction_lines_attributes: [
          {
            label: 'Milk pack',
            invoiced_quantity: 1,
            sublines_attributes: [
              {label: 'Milk bottle', unit: 'liter', invoiced_quantity: 4}
            ],
          },
        ]
      )

      expect{
        quote.update!(convert_until: 'order')
      }.to change{
        D::My::TransactionLine.count
      }.by(2)
    end

    it 'should compute amounts on update' do
      quote = D::My::Quote.create!(
        label: 'Test',
        transaction_lines_attributes: [
          {
            gross_unit_price: 250.0,
            invoiced_quantity: 2,
            vat_rate_attributes: {percent: 0.2, code: 'S'},
          },
        ]
      )
      quote.reload.update!(convert_until: 'order')
      expect(D::My::Order.first).to have_attributes(
        amount_excluding_vat: 500.0,
        vat_amount: 100.0,
        amount_including_vat: 600.0,
      )
    end

    it 'should compute amounts on create' do
      quote = D::My::Quote.create!(
        label: 'Test',
        convert_until: 'order',
        transaction_lines_attributes: [
          {
            gross_unit_price: 250.0,
            invoiced_quantity: 2,
            vat_rate_attributes: {percent: 0.2, code: 'S'},
          },
        ]
      )
      expect(D::My::Order.first).to have_attributes(
        amount_excluding_vat: 500.0,
        vat_amount: 100.0,
        amount_including_vat: 600.0,
      )
    end

    it 'should copy associations' do
      currency = D::My::Currency.first
      seller_account = D::My::Account.create!(name: 'Toto & co')
      buyer_account = D::My::Account.create!(name: 'Titi & cie')
      buyer_contact = D::My::Contact.create!(name: 'Titi')
      quote = D::My::Quote.create!(
        label: 'Test',
        convert_until: 'order',
        currency: currency,
        accounting_currency: currency,
        buyer_company: buyer_account,
        seller_company: seller_account,
        buyer_contact: buyer_contact,
        transaction_lines_attributes: [
          {
            gross_unit_price: 250.0,
            invoiced_quantity: 2,
            vat_rate_attributes: {percent: 0.2, code: 'S'},
          },
        ]
      )
      expect(D::My::Order.first).to have_attributes(
        amount_excluding_vat: 500.0,
        vat_amount: 100.0,
        amount_including_vat: 600.0,
        currency: currency,
        accounting_currency: currency,
        buyer_company: buyer_account,
        seller_company: seller_account,
        buyer_contact: buyer_contact,
      )
    end

    context 'invalid value' do

      it 'should not create a transaction retrospectively' do
        expect{
          D::My::Invoice.create!(convert_until: 'order')
        }.to not_change{
          D::My::Order.count
        }
      end

      it 'should not create a transaction when value correspond to klass' do
        expect{
          D::My::Order.create!(convert_until: 'order')
        }.to change{
          D::My::Order.count
        }.by(1)
      end

    end

  end

  context 'sumarize vat' do
    before(:each) do
      @quote = D::My::Quote.create!(
        label: 'Test',
        transaction_lines_attributes: [
          {
            gross_unit_price: 250.0,
            invoiced_quantity: 2,
            vat_rate_attributes: {percent: 0.2, code: 'S'},
          },
        ]
      )

      @quote.transaction_lines.create!(
        [
          {
            parent_id: @quote.transaction_lines.first.id,
            gross_unit_price: 20.44,
            quantity_for_single_unit_of_parent_line: 3,
            vat_rate_attributes: {percent: 0.1, code: 'S'}
          },
          {
            parent_id: @quote.transaction_lines.first.id,
            gross_unit_price: 10.98,
            quantity_for_single_unit_of_parent_line: 2,
            vat_rate_attributes: {percent: 0.1, code: 'S'}
          }
        ]
      )
    end

    it 'should compute correctly when regrouped by vat type' do
      expect(@quote.reload.compute_vat_breakdown).to eq(
        [
          {percent: 0.2, code: 'S', hint: 'Standard', excluding_vat: 500.0, vat_amount: 100.0, including_vat: 600.0},
          {percent: 0.1, code: 'S', hint: 'Standard', excluding_vat: 166.56, vat_amount: 16.66, including_vat: 183.22},
          {excluding_vat: 666.56, vat_amount: 116.66, including_vat: 783.22, excluding_vat_before_discounts: 666.56, excluding_vat_before_fees: 666.56},
        ]
      )
    end

    it 'should compute correctly when adding each computed line' do
      expect(@quote.reload.compute_vat_amount_from_lines).to eq(
        [
          {percent: 0.2, code: 'S', hint: 'Standard', excluding_vat: 500.0, vat_amount: 100.0, including_vat: 600.0},
          {percent: 0.1, code: 'S', hint: 'Standard', excluding_vat: 166.56, vat_amount: 16.65, including_vat: 183.21},
        ]
      )
    end

    context 'discounts and fees on transaction' do
      before(:each) do
        @quote.fees.create!(raw_value: 5.0, applicability: 'on_base')
        @quote.discounts.create!(percent: -0.05, applicability: 'on_base')
      end

      it 'should not include their vat amount to breakdown' do
        expect(@quote.reload.compute_vat_breakdown).to eq(
          [
            {percent: 0.2, code: 'S', hint: 'Standard', excluding_vat: 500.0, vat_amount: 100.0, including_vat: 600.0},
            {percent: 0.1, code: 'S', hint: 'Standard', excluding_vat: 166.56, vat_amount: 16.66, including_vat: 183.22},
            {excluding_vat: 638.23, vat_amount: 116.66, including_vat: 754.89, excluding_vat_before_discounts: 666.56, excluding_vat_before_fees: 633.23},
          ]
        )
      end

      xit 'should compute correctly when fees or discounts have a vat rate' do
      end
    end

  end

  describe '.compute_amounts' do

    context 'standard lines' do
      before(:each) do
        @quote = D::My::Quote.create!(
          label: 'Test',
          transaction_lines_attributes: [
            {
              gross_unit_price: 250.0,
              invoiced_quantity: 2,
              vat_rate_attributes: {percent: 0.2, code: 'S'},
            },
          ]
        )
        @quote.transaction_lines.create!(
          [
            {
              parent_id: @quote.transaction_lines.first.id,
              gross_unit_price: 20.0,
              quantity_for_single_unit_of_parent_line: 3,
              vat_rate_attributes: {percent: 0.1, code: 'S'}
            },
            {
              parent_id: @quote.transaction_lines.first.id,
              gross_unit_price: 10.0,
              quantity_for_single_unit_of_parent_line: 2,
              vat_rate_attributes: {percent: 0.1, code: 'S'}
            }
          ]
        )
      end

      it "should compute on transaction lines' update" do
        @quote.reload
        @quote.transaction_lines.first.update!(gross_unit_price: 200.0)
        @quote.reload
        expect(@quote).to have_attributes(
          amount_excluding_vat: 560.0,
          vat_amount: 96.0,
          amount_including_vat: 656.0,
        )
      end
    end

    context 'having lines as informations' do
      before(:each) do
        @attrs = {
          label: 'Test',
          transaction_lines_attributes: [
            {
              gross_unit_price: 50.0,
              vat_rate_attributes: {percent: 0.2, code: 'S'},
            },
            {
              type: 'D::My::TransactionLineInfo',
              gross_unit_price: 20.0,
              invoiced_quantity: 2,
              vat_rate_attributes: {percent: 0.2, code: 'S'},
            },
          ]
        }
      end

      it 'should compute without using information lines' do
        @quote = D::My::Quote.create!(@attrs)
        expect(@quote.reload).to have_attributes(
          amount_excluding_vat: 50.0,
          vat_amount: 10.0,
          amount_including_vat: 60.0,
        )
      end

    end

    context 'having lines as group' do
      before(:each) do
        @quote = D::My::Quote.create!(
          label: 'Test',
          transaction_lines_attributes: [
            {
              gross_unit_price: 50.0,
              vat_rate_attributes: {percent: 0.2, code: 'S'},
            },
            {
              type: 'D::My::TransactionLineGroup',
            },
          ]
        )

        parent_id = @quote.transaction_lines.last.id
        @quote.transaction_lines.create!(
          [
            {gross_unit_price: 50.0, parent_id: parent_id, vat_rate_attributes: {percent: 0.2, code: 'S'}},
            {gross_unit_price: 20.0, parent_id: parent_id, vat_rate_attributes: {percent: 0.2, code: 'S'}}
          ]
        )
      end

      it 'should compute without using group lines' do
        expect(@quote.reload).to have_attributes(
          amount_excluding_vat: 120.0,
          vat_amount: 24.0,
          amount_including_vat: 144.0,
        )
      end

    end

    context 'missing vat rate on line' do
      before(:each) do
        @quote = D::My::Quote.create!(
          label: 'Test',
          transaction_lines_attributes: [
            {
              gross_unit_price: 250.0,
              invoiced_quantity: 2,
            },
          ]
        )
      end

      it 'should compute amounts' do
        expect(@quote.reload).to have_attributes(
          amount_excluding_vat: 500.0,
          vat_amount: 0.0,
          amount_including_vat: 500.0,
        )
      end
    end

    context 'with amounts and fees on transaction' do
      before(:each) do
        @quote = D::My::Quote.create!(
          label: 'Test',
          transaction_lines_attributes: [
            {
              gross_unit_price: 250.0,
              invoiced_quantity: 2,
            },
          ],
          discounts_attributes: [
            {percent: -0.05, applicability: 'on_base'}
          ],
          fees_attributes: [
            {raw_value: 5.0, applicability: 'on_base'}
          ],
        )
      end

      it 'should compute amounts' do
        expect(@quote.reload).to have_attributes(
          amount_excluding_vat: 480.0,
          vat_amount: 0.0,
          amount_including_vat: 480.0,
        )
      end
    end

    context 'modifying transaction lines' do
      before(:each) do
        @quote = D::My::Quote.create!(
          label: 'Test',
          transaction_lines_attributes: [
            {
              gross_unit_price: 250.0,
              invoiced_quantity: 2,
              fees_attributes: [
                {raw_value: 5.0, applicability: 'on_base'}
              ],
            },
            {
              gross_unit_price: 50.0,
              invoiced_quantity: 1,
              discounts_attributes: [
                {percent: -0.05, applicability: 'on_base'}
              ],
            },
          ],
        )
        @quote.transaction_lines.first.fees.first.update!(owner: @quote.transaction_lines.first)
        @quote.transaction_lines.last.discounts.first.update!(owner: @quote.transaction_lines.last)
      end

      it 'should compute when removing a discount' do
        discounts = @quote.transaction_lines.last.discounts
        expect{
          discounts.delete(discounts.last)
        }.to change{
          @quote.reload.amount_excluding_vat
        }.from(552.5).to(555.0)
      end

      it 'should compute when destroying a discount' do
        expect{
          D::My::AppliedAmount.find_by(percent: -0.05).destroy!
        }.to change{
          @quote.reload.amount_excluding_vat
        }.from(552.5).to(555.0)
      end

      it 'should compute when removing a fee' do
        fees = @quote.transaction_lines.first.fees
        expect{
          fees.delete(fees.last)
        }.to change{
          @quote.reload.amount_excluding_vat
        }.from(552.5).to(547.5)
      end

      it 'should compute when destroying a fee' do
        expect{
          D::My::AppliedAmount.find_by(raw_value: 5).destroy!
        }.to change{
          @quote.reload.amount_excluding_vat
        }.from(552.5).to(547.5)
      end

      it 'should compute when removing a line' do
        expect{
          @quote.transaction_lines.delete(@quote.transaction_lines.last)
        }.to change{
          @quote.reload.amount_excluding_vat
        }.from(552.5).to(505.0)
      end

      it 'should compute when destroying a line' do
        expect{
          D::My::TransactionLine.find_by(gross_unit_price: 50.0).destroy!
        }.to change{
          @quote.reload.amount_excluding_vat
        }.from(552.5).to(505.0)
      end
    end

  end

end
