require "support/with_db_cache"

describe Dynamic::Transaction::Line::Base, elasticsearch: false, sidekiq: false, keep_schema: true do
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
  end

  after(:all) do
    User.current = nil
  end

  before(:each) do
    @schema = Dynamic::Schema.find_by!(name: 'My')
    @schema.unload
    @schema.load
  end

  describe 'create' do
    before(:each) do
      @quote = D::My::Quote.create!(label: 'Test')
      @vat_rate = D::My::Vat.create!(name: 'TVA 20%', percent: 0.2, code: 'S')
      @article = D::My::Article.create(
        name: 'Séjour Club Mid',
        gross_unit_price: 250.0,
        vat_rate: @vat_rate,
        package_members_attributes: [
          {
            quantity: 2,
            position: 0,
            target_article_attributes: {
              gross_unit_price: 200.0,
              vat_rate: @vat_rate,
              product_attributes: {
                reference: '123',
                name: 'Location chambre nuit complète',
                options_attributes: [
                  {
                    name: "Service d'étage"
                  },
                ],
                characteristics_attributes: [
                  {
                    name: 'Lit 2 places',
                  },
                ],
              }
            }
          },
          {
            quantity: 1,
            position: 1,
            target_article_attributes: {
              gross_unit_price: 100.0,
              vat_rate: @vat_rate,
              product_attributes: {
                reference: '456',
                name: 'Cours de paddle (enfants)',
              }
            },
          }
        ]
      )
    end

    context 'with article' do

      it 'should compute amount from article' do
        expect(D::My::TransactionLine.create!(article: @article)).to have_attributes(
          gross_unit_price: 250.0,
          amount_excluding_vat: 250.0,
          amount_including_vat: 300.0,
          vat_amount: 50.0,
          invoiced_quantity: 1.0,
          sublines: contain_exactly(
            have_attributes(amount_excluding_vat: 400.0, amount_including_vat: 480.0, vat_amount: 80.0, type: 'D::My::TransactionLineInfo'),
            have_attributes(amount_excluding_vat: 100.0, amount_including_vat: 120.0, vat_amount: 20.0, type: 'D::My::TransactionLineInfo'),
          )
        )
      end

      context 'having options' do
        before(:each) do
          @article.options.create!(
            [
              {
                name: 'Place de parking',
                gross_unit_price: 20.0,
                vat_rate: @vat_rate
              },
              {
                name: 'Pâtisserie de bienvenue',
              }
            ]
          )
        end

        it 'should compute lines from options' do
          expect(D::My::TransactionLine.create!(article: @article)).to have_attributes(
            parent: have_attributes(
              type: 'D::My::TransactionLineGroup',
              amount_excluding_vat: 270.0,
              amount_including_vat: 324.0,
              vat_amount: 54.0
            ),
            sublines: contain_exactly(
              have_attributes(amount_excluding_vat: 400.0, amount_including_vat: 480.0, vat_amount: 80.0, type: 'D::My::TransactionLineInfo'),
              have_attributes(amount_excluding_vat: 100.0, amount_including_vat: 120.0, vat_amount: 20.0, type: 'D::My::TransactionLineInfo'),
              have_attributes(amount_excluding_vat: 20.0, amount_including_vat: 24.0, vat_amount: 4.0, type: 'D::My::TransactionLine'),
              have_attributes(amount_excluding_vat: nil, amount_including_vat: nil, vat_amount: nil, type: 'D::My::TransactionLineInfo'),
            )
          )
        end

      end

      xcontext 'having discount and fees' do
        before(:each) do
          @article.update!(product_attributes: {name: 'Séjour Club Mid', reference: 'A38'})
          discounts = D::My::Discount.create!(
            [
              {name: 'Remise fidélité', raw_value: -5, discount_category: 'fidelity'},
              {name: 'Solde mi-saison', percent: -0.05, discount_category: 'clearance'},
            ]
          )
          fee = D::My::Fee.create!(name: 'Frais de livraison', raw_value: 20, fee_category: 'shipping_cost')
          D::My::R::Transaction::ApplicableAmount::Rule.create!(
            [
              {priority: 1, applicability: 'on_base', target: @article.product, amount: discounts.first},
              {priority: 2, applicability: 'previous_operation', target: @article.product, amount: discounts.last},
              {priority: 1, applicability: 'on_base', target: @article.product, amount: fee},
            ]
          )
        end

        it 'should compute amounts accordingly' do
          expect(D::My::TransactionLine.create!(article: @article)).to have_attributes(
            gross_unit_price: 250.0,
            net_unit_price: 250.0,
            amount_excluding_vat: 232.75,
            amount_including_vat: 279.3,
            vat_amount: 46.55,
            sublines: contain_exactly(
              have_attributes(amount_excluding_vat: 400.0, amount_including_vat: 480.0, vat_amount: 80.0, type: 'D::My::TransactionLineInfo'),
              have_attributes(amount_excluding_vat: 100.0, amount_including_vat: 120.0, vat_amount: 20.0, type: 'D::My::TransactionLineInfo'),
              have_attributes(label: 'Frais de livraison - Séjour Club Mid', amount_excluding_vat: 20.0, amount_including_vat: 20.0, vat_amount: 0.0, type: 'D::My::TransactionLineVat'), # Shipping cost has not VAT rate unlike product
            )
          )
        end

      end
    end

    context 'with sublines' do
      before(:each) do
        @attrs = {label: 'Pack', sublines_attributes: [{label: 'Article', gross_unit_price: 258.32}]}
      end

      it "should compute sublines' amount" do
        expect{
          D::My::TransactionLine.create!(@attrs)
        }.to change{
          D::My::TransactionLine.count
        }.by(2).and change{
          D::My::TransactionLine.find_by(label: 'Article')&.amount_excluding_vat
        }.from(nil).to(258.32).and not_change{
          D::My::TransactionLine.find_by(label: 'Pack')&.amount_excluding_vat
        }.from(nil)
      end

      context 'and article' do
        before(:each) do
          @attrs.merge!(article: @article)
        end

        it 'should compute amount from sublines' do
          expect{
            D::My::TransactionLine.create!(@attrs)
          }.to change{
            D::My::TransactionLine.count
          }.by(2).and change{
            D::My::TransactionLine.find_by(label: 'Article')&.amount_excluding_vat
          }.from(nil).to(258.32).and not_change{
            D::My::TransactionLine.find_by(label: 'Pack')&.amount_excluding_vat
          }.from(nil)
        end
      end

      context 'and gross_unit_price' do
        before(:each) do
          @attrs.merge!(gross_unit_price: 200.0)
        end

        it 'should compute amount from gross_unit_price' do
          expect{
            D::My::TransactionLine.create!(@attrs)
          }.to change{
            D::My::TransactionLine.count
          }.by(2).and change{
            D::My::TransactionLine.find_by(label: 'Article')&.amount_excluding_vat
          }.from(nil).to(258.32).and change{
            D::My::TransactionLine.find_by(label: 'Pack')&.amount_excluding_vat
          }.from(nil).to(200.0)
        end
      end
    end

    context 'with base_quantity_for_unit_price' do
      before(:each) do
        @attrs = {label: 'Nails', invoiced_quantity: 2, base_quantity_for_unit_price: 100, unit: 'piece', gross_unit_price: 3}
      end

      it 'should compute correctly' do
        line = D::My::TransactionLine.create!(@attrs)
        expect(line.amount_excluding_vat).to eq(6)
      end
    end

  end

  describe 'update' do
    before(:each) do
      @vat_rate = D::My::Vat.create!(name: 'TVA 20%', percent: 0.2, code: 'S')
      @article = D::My::Article.create(
        name: 'Séjour Club Mid',
        gross_unit_price: 250.0,
        vat_rate: @vat_rate,
        package_members_attributes: [
          {
            quantity: 2,
            position: 0,
            target_article_attributes: {
              gross_unit_price: 200.0,
              vat_rate: @vat_rate,
              product_attributes: {
                reference: '123',
                name: 'Location chambre nuit complète',
                options_attributes: [
                  {
                    name: "Service d'étage"
                  },
                ],
                characteristics_attributes: [
                  {
                    name: 'Lit 2 places',
                  },
                ],
              }
            }
          },
          {
            quantity: 1,
            position: 1,
            target_article_attributes: {
              gross_unit_price: 100.0,
              vat_rate: @vat_rate,
              product_attributes: {
                reference: '456',
                name: 'Cours de paddle (enfants)',
              }
            },
          }
        ]
      )
    end

    context 'parent line and quantites' do

      context 'updating parent quantities' do
        before(:each) do
          @transaction_line = D::My::TransactionLine.create!(article: @article)
        end

        it 'should update itself and its sublines' do
          @transaction_line.update!(invoiced_quantity: 2)
          expect(@transaction_line).to have_attributes(
            gross_unit_price: 250.0,
            amount_excluding_vat: 500.0,
            amount_including_vat: 600.0,
            vat_amount: 100.0,
            invoiced_quantity: 2.0,
            sublines: contain_exactly(
              have_attributes(invoiced_quantity: 4.0, amount_excluding_vat: 800.0, amount_including_vat: 960.0, vat_amount: 160.0, type: 'D::My::TransactionLineInfo'),
              have_attributes(invoiced_quantity: 2.0, amount_excluding_vat: 200.0, amount_including_vat: 240.0, vat_amount: 40.0, type: 'D::My::TransactionLineInfo'),
            )
          )
        end
      end

      context 'create line with exsting parent' do
        before(:each) do
          @parent_line = D::My::TransactionLine.create!(label: 'parent', invoiced_quantity: 2)
        end

        it 'should compute quantities when passing parent as a record' do
          @transaction_line = D::My::TransactionLine.create!(article: @article, parent: @parent_line)
          expect(@transaction_line.reload).to have_attributes(
            gross_unit_price: 250.0,
            amount_excluding_vat: 500.0,
            amount_including_vat: 600.0,
            vat_amount: 100.0,
            invoiced_quantity: 2.0,
            quantity_for_single_unit_of_parent_line: 1.0,
            sublines: contain_exactly(
              have_attributes(invoiced_quantity: 4.0, amount_excluding_vat: 800.0, amount_including_vat: 960.0, vat_amount: 160.0, type: 'D::My::TransactionLineInfo'),
              have_attributes(invoiced_quantity: 2.0, amount_excluding_vat: 200.0, amount_including_vat: 240.0, vat_amount: 40.0, type: 'D::My::TransactionLineInfo'),
            )
          )
        end

        it 'should compute quantities when passing parent as an id' do
          @transaction_line = D::My::TransactionLine.create!(article: @article, parent_id: @parent_line.id)
          expect(@transaction_line.reload).to have_attributes(
            gross_unit_price: 250.0,
            amount_excluding_vat: 500.0,
            amount_including_vat: 600.0,
            vat_amount: 100.0,
            invoiced_quantity: 2.0,
            sublines: contain_exactly(
              have_attributes(invoiced_quantity: 4.0, amount_excluding_vat: 800.0, amount_including_vat: 960.0, vat_amount: 160.0, type: 'D::My::TransactionLineInfo'),
              have_attributes(invoiced_quantity: 2.0, amount_excluding_vat: 200.0, amount_including_vat: 240.0, vat_amount: 40.0, type: 'D::My::TransactionLineInfo'),
            )
          )
        end

      end
    end

    context 'discounts and fees associations' do
      before(:each) do
        @transaction_line = D::My::TransactionLine.create!(article: @article)
      end

      it 'should compute line when adding one' do
        expect{
          @transaction_line.fees << D::My::AppliedAmount.create!(applicability: 'on_base', position: 0, raw_value: 10)
        }.to change{
          @transaction_line.amount_excluding_vat
        }.from(250.0).to(260.0)

        expect{
          @transaction_line.discounts << D::My::AppliedAmount.create!(applicability: 'on_base', position: 1, raw_value: -30)
        }.to change{
          @transaction_line.amount_excluding_vat
        }.from(260.0).to(230.0)
      end

      it 'should compute line when removing one' do
        @transaction_line.fees << D::My::AppliedAmount.create!(applicability: 'on_base', position: 0, raw_value: 10)
        expect{
          @transaction_line.fees.delete(@transaction_line.fees.last)
        }.to change{
          @transaction_line.amount_excluding_vat
        }.from(260.0).to(250.0)
      end

      it 'should compute line when editing one' do
        @transaction_line.fees << D::My::AppliedAmount.create!(applicability: 'on_base', position: 0, raw_value: 10, owner: @transaction_line)
        expect{
          @transaction_line.fees.update!(raw_value: 20)
        }.to change{
          @transaction_line.reload.amount_excluding_vat
        }.from(260.0).to(270.0)
      end

    end
  end

  describe 'destroy' do
    before(:each) do
      @quote = D::My::Quote.create!(
        label: 'Test',
        transaction_lines_attributes: [
          {
            id: '01a0c4ac-66e0-7dfc-aea6-bdcb87692220',
            type: 'D::My::TransactionLineGroup',
          },
          {
            parent_id: '01a0c4ac-66e0-7dfc-aea6-bdcb87692220',
            gross_unit_price: 250.0,
            quantity_for_single_unit_of_parent_line: 2,
            fees_attributes: [
              {raw_value: 5.0, applicability: 'on_base'}
            ],
          },
          {
            parent_id: '01a0c4ac-66e0-7dfc-aea6-bdcb87692220',
            gross_unit_price: 50.0,
            quantity_for_single_unit_of_parent_line: 1,
            discounts_attributes: [
              {percent: -0.05, applicability: 'on_base'}
            ],
          },
        ],
      )
    end

    it 'should recompute parent' do
      expect{
        D::My::TransactionLine.find_by(gross_unit_price: 50.0).destroy!
      }.to change{
        D::My::TransactionLine.find('01a0c4ac-66e0-7dfc-aea6-bdcb87692220').amount_excluding_vat
      }.from(552.5).to(505.0)
    end
  end

end
