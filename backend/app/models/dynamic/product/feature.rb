module Dynamic
  module Product
    module Feature; extend Dynamic::Feature

      REVERSE_DEPENDENCIES = [
        'Dynamic::Transaction::Feature',
      ].freeze

      def self.feature_attributes
        {
          human_name_fr: 'Produit',
          human_name_en: 'Product',
          mandatory: false,
          enabled: false,
          concerns_attributes: [
            {
              name: 'Article',
              human_name_fr: 'Article',
              human_name_en: 'Article',
              options_attributes: [
                {
                  name: 'visible_attribute',
                  human_name_fr: 'Attribut de la visibilité',
                  human_name_en: 'Visibility attribute',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  global: false,
                }
              ]
            }
          ],
          options_attributes: [
            {
              name: 'account_klass',
              human_name_fr: 'Table des comptes',
              human_name_en: 'Account Table',
              type: 'String',
              coder_type: 'Dynamic::Schema::Option::Coder::Klass',
              value: nil
            },
          ],
        }
      end

      def self.after_disabled(feature)
        REVERSE_DEPENDENCIES.each do |d|
          dependency = feature.schema.features.find_by!(name: d)
          dependency.update(enabled: false)
        end
      end

      def self.after_enabled(feature)
        schema = feature.schema
        account_klass = feature.options.detect {|o| o.name == 'account_klass'}.value
        unless account_klass
          feature.errors.add :enabled
          raise ActiveRecord::RecordInvalid.new(feature)
        end

        product = schema.klasses.find_by(name: 'Product') || self.create_product_klass(feature)
        product_package_line = schema.klasses.find_by(name: 'ProductPackageLine') || self.create_package_line_klass(feature)
        brand_klass = feature.schema.klasses.find_by(name: 'Brand') || self.create_brand_klass(feature)
        product_property = schema.klasses.find_by(name: 'ProductProperty') || self.create_product_property_klass(feature)
        product_property_value = schema.klasses.find_by(name: 'ProductPropertyValue') || self.create_product_property_value_klass(feature)
        category = schema.klasses.find_by(name: 'Category') || self.create_product_category_klass(feature)
        article  = schema.klasses.find_by(name: 'Article') || self.create_article_klass(feature)
        article_package_line = schema.klasses.find_by(name: 'ArticlePackageLine') || self.create_article_package_line_klass(feature)

        c = feature.concerns.detect {|c| c.name == 'Article'}
        c.update!(klass: article) unless c.klass
        visible_opt = c.options.detect {|o| o.name == 'visible_attribute'}
        visible_opt.update!(value: article.attrs.detect {|a| a.name == 'visible'}) unless visible_opt.value

        self.create_brand_product_associations(brand_klass, product)
        self.create_account_brand_associations(account_klass, brand_klass)
        self.create_product_product_property_associations(product, product_property, product_property_value)
        self.create_product_package_line_associations(product, product_package_line)
        self.create_category_cateogries_associations(category)
        self.create_category_product_associations(category, product)
        self.create_article_associations(article, product, product_property_value)
        self.create_article_package_line_associations(article, article_package_line)
      end

      def self.create_product_klass(feature)
        raw_data = {
          name: 'Product',
          human_name_fr: 'Produit',
          human_name_en: 'Product',
          plural_human_name_fr: 'Produits',
          plural_human_name_en: 'Products',
          icon: 'clipboard',
          table_profile: :huge,
          update_menu_items: false,
          attrs_attributes: [
            {
              id: '018e845a-8028-70e1-ad6a-de6d7ef11fea',
              type:'String',
              name: 'name',
              human_name_fr: 'Nom',
              human_name_en: 'Name',
            },
            {
              type: 'String',
              name: 'description',
              human_name_fr: 'Description',
              human_name_en: 'Description',
            },
            {
              id: '018e845a-be27-7bc6-a29a-9e1f4c70b1d2',
              type: 'String',
              name: 'reference',
              human_name_fr: 'Réference',
              human_name_en: 'Reference',
            },
            {
              type: 'Boolean',
              name: 'visible',
              human_name_fr: 'Visible',
              human_name_en: 'Visible',
            },
            {
              id: '018e845a-e1cb-76fa-8a1b-609474dcb501',
              type: 'DateTime',
              name: 'availability_start',
              human_name_fr: 'Début de diponibilité',
              human_name_en: 'Availability start',
            },
            {
              id: '018e845a-e1cb-76fa-8a1b-609474dcb502',
              type: 'DateTime',
              name: 'availability_end',
              human_name_fr: 'Fin de diponibilité',
              human_name_en: 'Availability end',
            },
            {
              type: 'Enum',
              name: 'validity',
              human_name_fr: 'Validité',
              human_name_en: 'Validity',
              values_attributes: [
                {
                  name: 'in_future',
                  human_name_fr: 'A venir',
                  human_name_en: 'In future',
                },
                {
                  name: 'ongoing',
                  human_name_fr: 'En cours',
                  human_name_en: 'Ongoing',
                },
                {
                  name: 'past',
                  human_name_fr: 'Passé',
                  human_name_en: 'Past',
                },
              ],
            },
            {
              id: '018e845b-aaf8-7c47-8a4e-b1ea069c34da',
              type: 'Float',
              name: 'quantity_max',
              human_name_fr: 'Quantité max',
              human_name_en: 'Quantity max',
            },
            {
              id: '018e845b-aaf8-7c47-8a4e-b1ea069c34d0',
              type: 'Float',
              name: 'quantity_min',
              human_name_fr: 'Quantité min',
              human_name_en: 'Quantity min',
            },
            {
              type: 'String',
              name: 'unity',
              human_name_fr: 'Unité',
              human_name_en: 'Unity',
            },
          ],
          validations_attributes: [
            {
              name: 'name_presence',
              type: 'Presence',
              attr_id: '018e845a-8028-70e1-ad6a-de6d7ef11fea',
              human_name_fr: 'Présence nom',
              human_name_en: 'Name presence',
            },
            {
              name: 'reference_presence',
              type: 'Presence',
              attr_id: '018e845a-be27-7bc6-a29a-9e1f4c70b1d2',
              human_name_fr: 'Présence reference',
              human_name_en: 'Reference presence',
            },
            {
              type: 'Comparison::Value',
              name: 'quantity_max_greater_than_zero',
              human_name_fr: 'Quantité Max > 0',
              human_name_en: 'Max Quanity > 0',
              attr_id: '018e845b-aaf8-7c47-8a4e-b1ea069c34da',
              operator: :greater_than,
              comparison_value: 0,
            },
            {
              type: 'Comparison::Value',
              name: 'quantity_min_greater_than_zero',
              human_name_fr: 'Quantité Min > 0',
              human_name_en: 'Min Quanity > 0',
              attr_id: '018e845b-aaf8-7c47-8a4e-b1ea069c34d0',
              operator: :greater_than,
              comparison_value: 0,
            },
            {
              type: 'Comparison::Attribute',
              name: 'quantity_max_grater_or_equal_quantity_min',
              human_name_fr: 'Quantité Max >= Quantité Min',
              human_name_en: 'Max Quanity >= Min Quanity',
              attr_id: '018e845b-aaf8-7c47-8a4e-b1ea069c34da',
              operator: :greater_than_or_equal_to,
              comparison_attr_id: '018e845b-aaf8-7c47-8a4e-b1ea069c34d0',
            },
            {
              type: 'Comparison::Attribute',
              name: 'availability_start_lesser_than_availability_end',
              human_name_fr: 'Date début diponibilité < Date fin diponibilité',
              human_name_en: 'Availability start date < availability end date',
              attr_id: '018e845a-e1cb-76fa-8a1b-609474dcb501',
              operator: :less_than,
              comparison_attr_id: '018e845a-e1cb-76fa-8a1b-609474dcb502',
            },
          ]
        }

        product_klass = feature.schema.klasses.create!(Dynamic::Feature::UuidConverter.replace_ids(raw_data, Dynamic::Schema::Klass))
        feature.schema.klasses.create!(
          name: 'Merchandise',
          human_name_fr: 'Marchandise',
          human_name_en: 'Merchandise',
          plural_human_name_fr: 'Marchandises',
          plural_human_name_en: 'Merchandise',
          icon: 'box-open',
          superklass: product_klass,
        )
        feature.schema.klasses.create!(
          name: 'Service',
          human_name_fr: 'Service',
          human_name_en: 'Service',
          plural_human_name_fr: 'Services',
          plural_human_name_en: 'Services',
          icon: 'hand-holding',
          superklass: product_klass,
        )

        return product_klass
      end

      def self.create_brand_klass(feature)
        raw_data = {
          name: 'Brand',
          human_name_fr: 'Marque',
          human_name_en: 'Brand',
          plural_human_name_fr: 'Marques',
          plural_human_name_en: 'Brands',
          icon: 'door-open',
          table_profile: :medium,
          attrs_attributes: [
            {
              id: '018f2866-2675-7acc-8062-b12c5ef647f0',
              type: 'String',
              name: 'name',
              human_name_fr: 'Nom',
              human_name_en: 'Name',
            },
            {
              type: 'String',
              name: 'short_name',
              human_name_fr: 'Nom court',
              human_name_en: 'Short name',
            },
            {
              type: 'String',
              name: 'description',
              human_name_fr: 'Description',
              human_name_en: 'Description',
            },
            {
              type: 'String',
              name: 'slogan',
              human_name_fr: 'Slogan',
              human_name_en: 'Slogan',
            },
          ],
          attachments_attributes: [
            {
              type: 'HasOne',
              name: 'logo',
              human_name_fr: 'Logo',
              human_name_en: 'Logo',
            }
          ],
          validations_attributes: [
            {
              name: 'name_presence',
              type: 'Presence',
              attr_id: '018f2866-2675-7acc-8062-b12c5ef647f0',
              human_name_fr: 'Présence nom',
              human_name_en: 'Name presence',
            },
          ]
        }
        feature.schema.klasses.create!(Dynamic::Feature::UuidConverter.replace_ids(raw_data, Dynamic::Schema::Klass))
      end

      def self.create_product_property_klass(feature)
        raw_data = {
          name: 'ProductProperty',
          human_name_fr: 'Propriété de produit',
          human_name_en: 'Product property',
          plural_human_name_fr: 'Propiétés de produit',
          plural_human_name_en: 'Product properties',
          icon: 'th-list',
          table_profile: :medium,
          attrs_attributes: [
            {
              id: '018e845b-ee6a-77a0-9f1c-7e7349652ca6',
              type: 'String',
              name: 'name',
              human_name_fr: 'Nom',
              human_name_en: 'Name',
            },
            {
              type: 'String',
              name: 'description',
              human_name_fr: 'Description',
              human_name_en: 'Description',
            },
          ],
          validations_attributes: [
            {
              name: 'name_presence',
              type: 'Presence',
              attr_id: '018e845b-ee6a-77a0-9f1c-7e7349652ca6',
              human_name_fr: 'Présence nom',
              human_name_en: 'Name presence',
            },
          ]
        }
        feature.schema.klasses.create!(Dynamic::Feature::UuidConverter.replace_ids(raw_data, Dynamic::Schema::Klass))
      end

      def self.create_product_property_value_klass(feature)
        raw_data = {
          name: 'ProductPropertyValue',
          human_name_fr: 'Valeur de Propriété de produit',
          human_name_en: 'Product property value',
          plural_human_name_fr: 'Valeurs de Propiété de produit',
          plural_human_name_en: 'Product propertie values',
          icon: 'th-list',
          table_profile: :medium,
          update_menu_items: false,
          attrs_attributes: [
            {
              id: '018e845b-ee6a-77a0-9f1c-7e7349652ca6',
              type: 'String',
              name: 'name',
              human_name_fr: 'Nom',
              human_name_en: 'Name',
            },
            {
              type: 'String',
              name: 'description',
              human_name_fr: 'Description',
              human_name_en: 'Description',
            },
          ],
          validations_attributes: [
            {
              name: 'name_presence',
              type: 'Presence',
              attr_id: '018e845b-ee6a-77a0-9f1c-7e7349652ca6',
              human_name_fr: 'Présence nom',
              human_name_en: 'Name presence',
            },
          ]
        }
        feature.schema.klasses.create!(Dynamic::Feature::UuidConverter.replace_ids(raw_data, Dynamic::Schema::Klass))
      end

      def self.create_package_line_klass(feature)
        raw_data = {
          name: 'ProductPackageLine',
          human_name_fr: 'Ligne de package',
          human_name_en: 'Package line',
          plural_human_name_fr: 'Lignes de package',
          plural_human_name_en: 'Package lines',
          icon: 'clipboard-list',
          table_profile: :medium,
          update_menu_items: false,
          attrs_attributes: [
            {
              id: '018ebc03-5b3d-7746-a1bf-4a20f74fb036',
              type: 'Integer',
              name: 'quantity',
              human_name_fr: 'Quantité',
              human_name_en: 'Quantity',
              locked: true,
            },
            {
              id: '018ebc03-5b3d-7746-a1bf-4a20f74fb037',
              type: 'Boolean',
              name: 'optional',
              human_name_fr: 'Optionel',
              human_name_en: 'Optional',
              locked: true,
            },
            {
              id: '018ebc03-5b3d-7746-a1bf-4a20f74fb038',
              type: 'Integer',
              name: 'position',
              human_name_fr: 'Position',
              human_name_en: 'Position',
              locked: true,
            },
          ],
          validations_attributes: [
            {
              name: 'quantity_presence',
              type: 'Presence',
              attr_id: '018ebc03-5b3d-7746-a1bf-4a20f74fb036',
              human_name_fr: 'Présence optionel',
              human_name_en: 'Optional presence',
            },
            {
              type: 'Comparison::Value',
              human_name_fr: 'Quantité > 0',
              human_name_en: 'Quantity > 0',
              attr_id: '018ebc03-5b3d-7746-a1bf-4a20f74fb036',
              operator: :greater_than,
              comparison_value: 0,
            },
            {
              name: 'position_presence',
              type: 'Presence',
              attr_id: '018ebc03-5b3d-7746-a1bf-4a20f74fb038',
              human_name_fr: 'Présence position',
              human_name_en: 'Position presence',
            },
          ]
        }
        feature.schema.klasses.create!(Dynamic::Feature::UuidConverter.replace_ids(raw_data, Dynamic::Schema::Klass))
      end

      def self.create_product_category_klass(feature)
        raw_data = {
          name: 'ProductCategory',
          human_name_fr: 'Categorie de Produit',
          human_name_en: 'Product Category',
          plural_human_name_fr: 'Catégories de produit',
          plural_human_name_en: 'Product categories',
          icon: 'tags',
          table_profile: :medium,
          update_menu_items: false,
          attrs_attributes: [
            {
              id: '018e845a-0520-7d52-8357-33fee5536e14',
              type: 'String',
              name: 'name',
              human_name_fr: 'Nom',
              human_name_en: 'Name',
            },
            {
              type: 'String',
              name: 'description',
              human_name_fr: 'Description',
              human_name_en: 'Description',
            },
          ],
          validations_attributes: [
            {
              name: 'name_presence',
              type: 'Presence',
              attr_id: '018e845a-0520-7d52-8357-33fee5536e14',
              human_name_fr: 'Présence nom',
              human_name_en: 'Name presence',
            },
          ]
        }
        feature.schema.klasses.create!(Dynamic::Feature::UuidConverter.replace_ids(raw_data, Dynamic::Schema::Klass))
      end

      def self.create_article_klass(feature)
        raw_data = {
          name: 'Article',
          human_name_fr: 'Article',
          human_name_en: 'Article',
          plural_human_name_fr: 'Articles',
          plural_human_name_en: 'Articles',
          icon: 'clipboard-check',
          table_profile: :medium,
          attrs_attributes: [
            {
              id: '018e845c-7eb2-7dec-b362-a445ad62b46e',
              type: 'String',
              name: 'name',
              human_name_fr: 'Nom',
              human_name_en: 'Name',
            },
            {
              type: 'Boolean',
              name: 'visible',
              human_name_fr: 'Visible',
              human_name_en: 'Visible',
            },
          ],
          validations_attributes: [
            {
              name: 'name_presence',
              type: 'Presence',
              attr_id: '018e845c-7eb2-7dec-b362-a445ad62b46e',
              human_name_fr: 'Présence du nom',
              human_name_en: 'Name presence',
            },
          ]
        }
        feature.schema.klasses.create!(Dynamic::Feature::UuidConverter.replace_ids(raw_data, Dynamic::Schema::Klass))
      end

      def self.create_article_package_line_klass(feature)
        raw_data = {
          name: 'ArticlePackageLine',
          human_name_fr: 'Ligne de paquet d\'article',
          human_name_en: 'Article package line',
          plural_human_name_fr: 'Lignes de paquet d\'article',
          plural_human_name_en: 'Article package lines',
          icon: 'clipboard-list',
          table_profile: :medium,
          update_menu_items: false,
          attrs_attributes: [
            {
              id: '018e845c-c392-79a2-855d-3ede8814815d',
              type: 'Float',
              name: 'quantity',
              human_name_fr: 'Quantité',
              human_name_en: 'Quantity',
              locked: true,
            },
            {
              id: '018e845c-c392-79a2-855d-3ede8814815e',
              type: 'Integer',
              name: 'position',
              human_name_fr: 'Position',
              human_name_en: 'Position',
              locked: true,
            },
          ],
          validations_attributes: [
            {
              name: 'quantity_presence',
              type: 'Presence',
              attr_id: '018e845c-c392-79a2-855d-3ede8814815d',
              human_name_fr: 'Présence de la quantité',
              human_name_en: 'Quantity presence',
            },
            {
              name: 'position_presence',
              type: 'Presence',
              attr_id: '018e845c-c392-79a2-855d-3ede8814815e',
              human_name_fr: 'Présence de la position',
              human_name_en: 'Position presence',
            },
          ]
        }
        feature.schema.klasses.create!(Dynamic::Feature::UuidConverter.replace_ids(raw_data, Dynamic::Schema::Klass))
      end

      def self.create_account_brand_associations(account_klass, brand_klass)
        brand_account = brand_klass.associations.create_with(
          human_name_fr: 'Compte',
          human_name_en: 'Account',
        ).find_or_create_by!(
          name: 'account',
          type: 'BelongsTo',
          target_klass: account_klass,
        )

        account_brands = account_klass.associations.create_with(
          human_name_fr: 'Marques',
          human_name_en: 'Brands',
        ).find_or_create_by!(
          name: 'brands',
          type: 'HasMany',
          target_klass: brand_klass,
          inverse_of: brand_account,
        )
        brand_account.update!(inverse_of: account_brands)
      end

      def self.create_brand_product_associations(brand_klass, product)
        product_brand = product.associations.create_with(
          human_name_fr: 'Marque',
          human_name_en: 'Brand',
        ).find_or_create_by!(
          name: 'brand',
          type: 'BelongsTo',
          target_klass: brand_klass,
        )

        brand_products = brand_klass.associations.create_with(
          human_name_fr: 'Produits',
          human_name_en: 'Products',
        ).find_or_create_by!(
          name: 'products',
          type: 'HasMany',
          target_klass: product,
          inverse_of: product_brand,
        )
        product_brand.update!(inverse_of: brand_products)
      end

      def self.create_product_product_property_associations(product, product_property, product_property_value)
        product.associations.create_with(
          human_name_fr: 'Options',
          human_name_en: 'Options',
          locked: true,
        ).find_or_create_by!(
          name: 'options',
          type: 'HasMany',
          target_klass: product_property,
        )
        product.associations.create_with(
          human_name_fr: 'Caractéristiques',
          human_name_en: 'Characteristics',
        ).find_or_create_by!(
          name: 'characteristics',
          type: 'HasMany',
          target_klass: product_property,
        )

        product_property_value_property = product_property.associations.create_with(
          human_name_fr: 'Valeurs',
          human_name_en: 'Values',
        ).find_or_create_by!(
          name: 'values',
          type: 'HasMany',
          target_klass: product_property_value,
        )

        product_property_values = product_property_value.associations.create_with(
          human_name_fr: 'Propriété',
          human_name_en: 'Property',
        ).find_or_create_by!(
          name: 'property',
          type: 'BelongsTo',
          target_klass: product_property,
          inverse_of: product_property_value_property,
        )
        product_property_value_property.update!(inverse_of: product_property_values)
      end

      def self.create_product_package_line_associations(product, product_package_line)
        product_package_product = product_package_line.associations.create_with(
          human_name_fr: 'Package',
          human_name_en: 'Package',
        ).find_or_create_by!(
          name: 'package',
          type: 'BelongsTo',
          target_klass: product,
        )
        product_product_packages = product.associations.create_with(
          human_name_fr: 'Membres du package',
          human_name_en: 'Package members',
          dependent_destroy: true,
          locked: true,
        ).find_or_create_by!(
          name: 'package_members',
          type: 'HasMany',
          target_klass: product_package_line,
          inverse_of: product_package_product,
        )
        product_package_product.update!(inverse_of: product_product_packages)

        product_package_line.associations.create_with(
          human_name_fr: 'Produit cible',
          human_name_en: 'Target product',
          locked: true,
        ).find_or_create_by!(
          name: 'target_product',
          type: 'BelongsTo',
          target_klass: product,
        )
      end

      def self.create_category_cateogries_associations(category)
        category_parent = category.associations.create_with(
          human_name_fr: 'Catégorie parent',
          human_name_en: 'Parent category',
        ).find_or_create_by!(
          name: 'parent',
          type: 'BelongsTo',
          target_klass: category,
        )
        category_categories = category.associations.create_with(
          human_name_fr: 'Sous Catégories',
          human_name_en: 'Subcategories',
        ).find_or_create_by!(
          name: 'subcategories',
          type: 'HasMany',
          target_klass: category,
          inverse_of: category_parent,
        )
        category_parent.update!(inverse_of: category_categories)
      end

      def self.create_category_product_associations(category, product)
        category_products = category.associations.create_with(
          human_name_fr: 'Produits',
          human_name_en: 'Products',
        ).find_or_create_by!(
          name: 'products',
          type: 'HasMany',
          target_klass: product,
        )

        product_categories = product.associations.create_with(
          human_name_fr: 'Catégories',
          human_name_en: 'Categories',
        ).find_or_create_by!(
          name: 'categories',
          type: 'HasMany',
          target_klass: category,
          inverse_of: category_products,
        )
        category_products.update!(inverse_of: product_categories)
      end

      def self.create_article_package_line_associations(article, article_package_line)
        article_package_line_article = article_package_line.associations.create_with(
          human_name_fr: 'Paquet',
          human_name_en: 'Package',
        ).find_or_create_by!(
          name: 'package',
          type: 'BelongsTo',
          target_klass: article,
        )
        article_article_package_lines = article.associations.create_with(
          human_name_fr: 'Membres du paquet',
          human_name_en: "Package's members",
          dependent_destroy: true,
          locked: true,
        ).find_or_create_by!(
          name: 'package_members',
          type: 'HasMany',
          target_klass: article_package_line,
          inverse_of: article_package_line_article,
        )
        article_package_line_article.update!(inverse_of: article_article_package_lines, locked: true)

        article_package_line.associations.create_with(
          human_name_fr: 'Article ciblé',
          human_name_en: 'Target article',
          locked: true,
        ).find_or_create_by!(
          name: 'target_article',
          type: 'BelongsTo',
          target_klass: article,
        )
      end

      def self.create_article_associations(article, product, product_property_value)
        article_product = article.associations.create_with(
          human_name_fr: 'Produit',
          human_name_en: 'Product',
        ).find_or_create_by!(
          name: 'product',
          type: 'BelongsTo',
          target_klass: product,
        )
        product_articles = product.associations.create_with(
          human_name_fr: 'Articles',
          human_name_en: 'Articles',
        ).find_or_create_by!(
          name: 'articles',
          type: 'HasMany',
          target_klass: article,
          inverse_of: article_product,
        )
        article_product.update!(inverse_of: product_articles)

        article.associations.create_with(
          human_name_fr: 'Options sélectionnées',
          human_name_en: 'Selected options',
          locked: true,
        ).find_or_create_by!(
          name: 'options',
          type: 'HasMany',
          target_klass: product_property_value,
        )
      end

    end
  end
end
