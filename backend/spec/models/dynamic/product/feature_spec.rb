describe Dynamic::Product::Feature, elasticsearch: false, sidekiq: false do
  before(:each) do
    @schema = Dynamic::Schema.create!(name: 'my')
    @feature = @schema.features.find_by(name: 'Dynamic::Product::Feature')

    Dynamic::Schema.load(@schema.name)
  end

  after(:each) do
    @schema.unload
  end

  it 'should raise when Account klass is missing from option' do
    expect{
      @feature.update!(enabled: true)
    }.to raise_error{ActiveRecord::RecordInvalid}
  end

  context 'when enabled' do
    before(:each) do
      @account_klass = @schema.klasses.create!(name: 'Account')
      @feature.options.detect {|o| o.name == 'account_klass'}.update!(value: @account_klass)
    end

    it 'should create klasses' do
      expect{
        @feature.update!(enabled: true)
      }.to change{
        @schema.reload.klasses.map(&:name)
      }.from(
        contain_exactly('Account')
      ).to(
        contain_exactly(
          'Account',
          'Product',
          'Merchandise',
          'Service',
          'ProductCategory',
          'ProductProperty',
          'ProductPropertyValue',
          'Brand',
          'ProductPackageLine',
          'Article',
          'ArticlePackageLine'
        )
      )
    end

    it 'should create Product subclasses' do
      expect{
        @feature.update!(enabled: true)
      }.to change{
        @schema.reload.klasses.select {|k| k.name.in?(['Merchandise', 'Service'])}.count
      }.from(0).to(2)
    end

    it 'should create Product associations' do
      expect{
        @feature.update!(enabled: true)
      }.to change{
        product_klass = @schema.klasses.detect {|k| k.name == 'Product'}
        Dynamic::Schema::Association::Base.where(owner_klass: product_klass).pluck(:name)
      }.from([]).to(contain_exactly('options', 'characteristics', 'package_members', 'categories', 'brand', 'articles'))
    end

    it 'should create ProductPackageLine associations' do
       expect{
        @feature.update!(enabled: true)
      }.to change{
        product_option_klass = @schema.klasses.detect {|k| k.name == 'ProductPackageLine'}
        Dynamic::Schema::Association::Base.where(owner_klass: product_option_klass).pluck(:name)
      }.from([]).to(contain_exactly('package', 'target_product'))
    end

    it 'should create Brand associations' do
       expect{
        @feature.update!(enabled: true)
      }.to change{
        brand_klass = @schema.klasses.detect {|k| k.name == 'Brand'}
        Dynamic::Schema::Association::Base.where(owner_klass: brand_klass).pluck(:name)
      }.from([]).to(contain_exactly('products', 'account'))
    end

    it 'should create Account associations' do
       expect{
        @feature.update!(enabled: true)
      }.to change{
        Dynamic::Schema::Association::Base.where(owner_klass: @account_klass).pluck(:name)
      }.from([]).to(contain_exactly('brands'))
    end

    it 'should create ProductProperty associations' do
       expect{
        @feature.update!(enabled: true)
      }.to change{
        product_option_klass = @schema.klasses.detect {|k| k.name == 'ProductProperty'}
        Dynamic::Schema::Association::Base.where(owner_klass: product_option_klass).pluck(:name)
      }.from([]).to(contain_exactly('values'))
    end

    it 'should create ProductCategory associations' do
       expect{
        @feature.update!(enabled: true)
      }.to change{
        product_category_klass = @schema.klasses.detect {|k| k.name == 'ProductCategory'}
        Dynamic::Schema::Association::Base.where(owner_klass: product_category_klass).pluck(:name)
      }.from([]).to(contain_exactly('subcategories', 'parent', 'products'))
    end

    it 'should create Article associations' do
       expect{
        @feature.update!(enabled: true)
      }.to change{
        article_klass = @schema.klasses.detect {|k| k.name == 'Article'}
        Dynamic::Schema::Association::Base.where(owner_klass: article_klass).pluck(:name)
      }.from([]).to(contain_exactly('options', 'product', 'package_members'))
    end

    it 'should create ArticlePackageLine associations' do
       expect{
        @feature.update!(enabled: true)
      }.to change{
        owner_klass = @schema.klasses.detect {|k| k.name == 'ArticlePackageLine'}
        Dynamic::Schema::Association::Base.where(owner_klass: owner_klass).pluck(:name)
      }.from([]).to(contain_exactly('package', 'target_article'))
    end

  end

end
