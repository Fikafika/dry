require "support/with_db_cache"

describe Dynamic::Transaction::Line::Group, elasticsearch: false, sidekiq: false, keep_schema: true do
  before(:all) do
    with_db_cache('transaction002') do
      User.current = User.create!(last_name: 'albert', email: 'albert@mousquetaire.fr', login: 'albert@mousquetaire.fr')
      @schema = Dynamic::Schema.create!(name: 'my')
      @schema.features.find_by(name: 'Dynamic::Permission::Feature').update!(enabled: false)

      @feature = @schema.features.find_by(name: 'Dynamic::Transaction::Feature')

      contact = @schema.klasses.create!(name: 'Contact', attrs_attributes: [name: 'name', type: 'String'])
      account = @schema.klasses.create!(name: 'Account', attrs_attributes: [name: 'name', type: 'String'])

      @feature.options.detect {|f| f.name == 'contact_klass'}.update!(value: contact)

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

  it "should compute its amount by adding sublines' amount" do
    @lines = D::My::TransactionLine.create!(
      [
        {
          id: '018e845a-0520-7d52-8357-33fee5536e14',
          type: 'D::My::TransactionLineGroup'
        },
        {
          parent_id: '018e845a-0520-7d52-8357-33fee5536e14',
          gross_unit_price: 5.0,
          quantity_for_single_unit_of_parent_line: 2,
          vat_rate_attributes: {percent: 0.2, code: 'S'},
        }
      ]
    )
    expect(@lines.last.reload).to have_attributes(
      amount_excluding_vat: 10.0,
      vat_amount: 2.0,
      amount_including_vat: 12.0,
    )
  end

  it 'should compute its amount without using information lines' do
    @lines = D::My::TransactionLine.create!(
      [
        {
          id: '018e845a-0520-7d52-8357-33fee5536e14',
          type: 'D::My::TransactionLineGroup'
        },
        {
          parent_id: '018e845a-0520-7d52-8357-33fee5536e14',
          gross_unit_price: 5.0,
          quantity_for_single_unit_of_parent_line: 2,
          vat_rate_attributes: {percent: 0.2, code: 'S'},
        },
        {
          type: 'D::My::TransactionLineInfo',
          gross_unit_price: 7.0,
          vat_rate_attributes: {percent: 0.2, code: 'S'}
        }
      ]
    )
    expect(@lines.second.reload).to have_attributes(
      amount_excluding_vat: 10.0,
      vat_amount: 2.0,
      amount_including_vat: 12.0,
    )
  end

  context 'removing from parent and sublines associations' do
    before(:each) do
      @lines = D::My::TransactionLine.create!(
        [
          {
            id: '018e845a-0520-7d52-8357-33fee5536e14',
            type: 'D::My::TransactionLineGroup'
          },
          {
            parent_id: '018e845a-0520-7d52-8357-33fee5536e14',
            gross_unit_price: 5.0,
            quantity_for_single_unit_of_parent_line: 2,
            vat_rate_attributes: {percent: 0.2, code: 'S'},
          }
        ]
      )
      @group = @lines.first
      @subline = @lines.second
      @lines.each(&:reload)
    end

    it 'should update its amount when destroying sublines' do
      expect{
        @group.sublines.destroy_all
      }.to change{
        @group.reload.amount_excluding_vat
      }.from(10).to(0)
    end

    it 'should update its amount removing sublines' do
      expect{
        @group.sublines = []
        @group.save!
      }.to change{
        @group.reload.amount_excluding_vat
      }.from(10).to(0)
    end

    it 'should update its amount when line adding a subline' do
      expect{
        line = D::My::TransactionLine.create!(gross_unit_price: 5.0)
        @group.sublines << line
      }.to change{
        @group.reload.amount_excluding_vat
      }.from(10).to(15)
    end

    it 'should update its amount when line remove it from parent' do
      expect{
        @subline.update!(parent: nil)
      }.to change{
        @group.reload.amount_excluding_vat
      }.from(10).to(0)
    end
  end

end
