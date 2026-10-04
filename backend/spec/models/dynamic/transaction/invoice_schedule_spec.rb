require "support/with_db_cache"

describe Dynamic::Transaction::InvoiceSchedule, elasticsearch: false, sidekiq: false, keep_schema: true do
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
      @base_attrs = {
        begin_at: Date.current - 2.days,
        recurrency: 'monthly',
        kind: 'payment_in_installments'
      }
    end

    context 'invalid' do

      it 'should raise error when due_date_count is negative, nil or zero' do
        expect{D::My::InvoiceSchedule.create!(@base_attrs.merge(amount: 500.0, due_date_count: 0))}.to raise_error{ActiveRecord::RecordInvalid}
        expect{D::My::InvoiceSchedule.create!(@base_attrs.merge(amount: 500.0, due_date_count: -2))}.to raise_error{ActiveRecord::RecordInvalid}
        expect{D::My::InvoiceSchedule.create!(@base_attrs.merge(amount: 500.0, due_date_count: nil))}.to raise_error{ActiveRecord::RecordInvalid}
      end

      it "should raise error when amount is greater than order's amount" do
        order = D::My::Order.create!(
          reference: 'A38',
          transaction_lines_attributes: [
            {
              label: 'Administrative paper',
              net_unit_price: 500.0,
            }
          ]
        )
        schedule_attrs = @base_attrs.merge(
          order: order,
          amount: 600.0,
          due_date_count: 2
        )
        expect{D::My::InvoiceSchedule.create!(schedule_attrs)}.to raise_error{ActiveRecord::RecordInvalid}
      end

    end

    context 'valid' do

      it 'should generate due_dates' do
        order = D::My::Order.create!(reference: 'A38')
        D::My::TransactionLine.create!(
          label: 'Administrative paper',
          gross_unit_price: 500.0,
          owner_transaction: order
        )
        order.reload
        schedule = D::My::InvoiceSchedule.create!(@base_attrs.merge(order: order, due_date_count: 2))
        expect(schedule.due_dates.count).to eq(2)
        expect(schedule.due_dates).to contain_exactly(
          have_attributes(
            amount: 250.0,
            position: 1,
            scheduled_date: be_between(@base_attrs[:begin_at], @base_attrs[:begin_at] + 1.day)
          ),
          have_attributes(
            amount: 250.0,
            position: 2,
            scheduled_date: be_between(@base_attrs[:begin_at] + 1.month, @base_attrs[:begin_at] + 1.day + 1.month)
          ),
        )
      end

      context 'when splitting will result in a remainder' do
        before(:each) do
          @order = D::My::Order.create!(reference: 'A38')
          @order.transaction_lines.create!(
            label: 'Administrative paper',
            gross_unit_price: 500.0,
          )
          @order.reload
        end

        it 'should generate invoices with same amounts except for the last one' do
          schedule = D::My::InvoiceSchedule.create!(@base_attrs.merge(order: @order, max_amount_per_due_date: 200.0))
          expect(schedule.due_dates.map(&:amount)).to eq([200.0, 200.0, 100.0])
        end

      end

      context 'subcription' do
        before(:each) do
          @base_attrs.merge!(kind: 'subscription')
        end

        it 'should create a single record when due date is excpected' do
          schedule = D::My::InvoiceSchedule.create!(@base_attrs.merge!(amount: 20.0, begin_at: DateTime.current + 2.days))
          expect(schedule.due_dates.count).to eq(1)
          expect(schedule.due_dates.first).to have_attributes(
            amount: 20.0,
            position: 1,
            validity: 'in_future',
            scheduled_date: be_between(@base_attrs[:begin_at] - 1.second, @base_attrs[:begin_at] + 1.day)
          )
        end

        it 'should create multiple records when dates are due since begin_at' do
          schedule = D::My::InvoiceSchedule.create!(@base_attrs.merge(amount: 20.0, begin_at: @base_attrs[:begin_at] - 2.months))
          expect(schedule.due_dates.count).to eq(4)
          expect(schedule.due_dates).to contain_exactly(
            have_attributes(
              amount: 20.0,
              position: 1,
              validity: 'ongoing',
              scheduled_date: be_between(@base_attrs[:begin_at] - 2.month, @base_attrs[:begin_at] - 2.month + 1.day)
            ),
            have_attributes(
              amount: 20.0,
              position: 2,
              validity: 'ongoing',
              scheduled_date: be_between(@base_attrs[:begin_at] - 1.month, @base_attrs[:begin_at] - 1.month + 1.day)
            ),
            have_attributes(
              amount: 20.0,
              position: 3,
              validity: 'ongoing',
              scheduled_date: be_between(@base_attrs[:begin_at] - 1.second, @base_attrs[:begin_at] + 1.day)
            ),
            have_attributes(
              amount: 20.0,
              position: 4,
              validity: 'in_future',
              scheduled_date: be_between(@base_attrs[:begin_at] + 1.month, @base_attrs[:begin_at] + 1.month + 1.day)
            ),
          )
        end

        it 'should generate an invoice when a date is due' do
          order = D::My::Order.create!(reference: 'A38')
          line = D::My::TransactionLine.create!(
            label: 'Phone subscription',
            gross_unit_price: 20.0,
            owner_transaction: order
          )
          order.reload
          schedule = D::My::InvoiceSchedule.create!(@base_attrs.merge(order: order, targeted_line: line))
          expect(schedule.due_dates.first.invoice.invoice_order_ids).to eq([order.id])
          expect(schedule.due_dates.first.invoice.transaction_lines.first).to eq(line)
          expect(schedule.due_dates.first.invoice.amount_including_vat).to eq(20.0)
          expect(schedule.due_dates.last.invoice_id).to be nil
        end

      end

    end

  end

  describe 'update' do

    context 'cancelation' do
      before(:each) do
        order = D::My::Order.create!(reference: 'A38')
        D::My::TransactionLine.create!(
          label: 'Administrative paper',
          gross_unit_price: 500.0,
          owner_transaction: order
        )
        order.reload
        @schedule = D::My::InvoiceSchedule.create!(
          begin_at: Date.current - 2.days,
          recurrency: 'monthly',
          kind: 'payment_in_installments',
          order: order,
          due_date_count: 2
        )
      end

      it 'should cancel its due dates' do
        expect{
          @schedule.update!(canceled: true)
        }.to change{
          D::My::InvoiceDueDate.all.map(&:canceled)
        }.from([nil, nil]).to([nil, true])
      end
    end
  end

  describe 'DateValidity' do

    context 'when scheduled_date is reached' do
      before(:each) do
        @due_date = D::My::InvoiceDueDate.create!(scheduled_date: DateTime.current - 3.days, amount: 20.0)
      end

      it 'should update validity on' do
        expect(@due_date).to have_attributes(validity: 'ongoing')
      end

      xit 'should not register a job' do
      end

    end

    context 'when scheduled_date is not reached' do
      before(:each) do
        @due_date = D::My::InvoiceDueDate.create!(scheduled_date: DateTime.current + 3.days, amount: 20.0)
      end

      it 'should update validity' do
        expect(@due_date).to have_attributes(validity: 'in_future')
      end

      xit 'should register a job' do
      end

    end

  end

end
