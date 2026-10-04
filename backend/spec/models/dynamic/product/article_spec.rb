describe Dynamic::Product::Article, elasticsearch: false, sidekiq: false do
  before(:each) do
    @schema = Dynamic::Schema.create!(name: 'my')
    @feature = @schema.features.find_by(name: 'Dynamic::Product::Feature')
    @account_klass = @schema.klasses.create!(name: 'Account')
    @feature.options.detect {|o| o.name == 'account_klass'}.update!(value: @account_klass)
  end

  context 'when enabled' do
    before(:each) do
      @feature.update!(enabled: true)
      Dynamic::Schema.load(@schema.name)
    end

    context 'create' do
      before(:each) do
        @product = D::My::Product.create!(
          reference: 'zzz',
          name: 'Séjour Club Mid',
          package_members_attributes: [
            {
              quantity: 2,
              position: 0,
              target_product_attributes: {
                reference: 'A38',
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
            },
            {
              quantity: 1,
              position: 1,
              optional: true,
              target_product_attributes: {
                reference: 'CPT',
                name: 'Cours de paddle (enfants)'
              },
            }
          ]
        )
      end

      context 'without package members' do
        before(:each) do
          @article = D::My::Article.create!(name: 'Séjour Club Mid - Offre de mi-saison', product: @product)
        end

        it "should copy product's package members" do
          expect(@article.package_members).to contain_exactly(
            having_attributes(
              position: 0,
              quantity: 2.0,
              target_article: have_attributes(
                name: 'Location chambre nuit complète',
              )
            ),
            have_attributes(
              position: 1,
              quantity: 1.0,
              target_article: have_attributes(name: 'Cours de paddle (enfants)')
            )
          )
        end

      end

      context 'without name' do
        before(:each) do
          @article = D::My::Article.create!(product: @product)
        end

        it "should copy product's name" do
          expect(@article.name).to eq(@product.name)
        end
      end

      context 'with package members and no product' do
        before(:each) do
          @article = D::My::Article.create(
            name: 'Séjour Club Mid',
            package_members_attributes: [
              {
                quantity: 2,
                position: 0,
                target_article_attributes: {
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
                  product_attributes: {
                    reference: '456',
                    name: 'Cours de paddle (enfants)',
                  }
                },
              }
            ]
          )
        end

        it 'should not create product' do
          expect(@article.product).to be nil
        end
      end

    end

  end

end
