#!/usr/local/bin/ruby

require File.expand_path('../../../config/environment', __dir__)

User.define_singleton_method(:current) do
  User.where(email: 'contact@kosmopolead.com').first
end

OpenSearch::Model.client.wait_for_server

@schema = Dynamic::Schema.where(name: 'Uneek').first

country_feature = @schema.features.detect{|e| e.name =~ /Country/}
country_feature.update!(enabled: true)

currency_feature = @schema.features.detect{|e| e.name =~ /Currency/}
currency_feature.update!(enabled: true)

product_feature = @schema.features.detect{|e| e.name =~ /Product/}
account_klass = @schema.klasses.detect {|k| k.name == 'Account'} || @schema.klasses.create!(name: 'Account')
product_feature.options.detect {|f| f.name == 'account_klass'}.update!(value: account_klass)
product_feature.update!(enabled: true)

amount_feature = @schema.features.detect{|e| e.name =~ /Amount/}
amount_feature.update!(enabled: true)

transaction_feature = @schema.features.detect{|e| e.name =~ /Transaction/}
contact_klass = @schema.klasses.detect {|k| k.name == 'Contact'} || @schema.klasses.create!(name: 'Contact')

transaction_feature.options.detect {|f| f.name == 'contact_klass'}.update!(value: contact_klass)
transaction_feature.update!(enabled: true)


@schema.load

product = D::Uneek::Product.create!(
  name: 'Séjour Club Mid',
  reference: 'SCM',
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
      target_product_attributes: {
        reference: 'CPT',
        name: 'Cours de paddle (enfants)'
      }
    }
  ]
)

article = D::Uneek::Article.create!(name: 'Séjour Club Mid - Offre de mi-saison', product: product)

vats = D::Uneek::Vat.create!(
  [
    {code: 'S', percent: 0.2},
    {code: 'S', percent: 0.1},
    {code: 'S', percent: 0.055},
  ]
)

currency = D::Uneek::Currency.where(iso_code: 'EUR').first

D::Uneek::Invoice.create!(
  currency: currency,
  transaction_lines_attributes: [
    {
      id: '019d1b3f-1420-753b-96b9-ce50c548a9c8',
      label: 'Echantillon',
      gross_unit_price: 50,
      unit: 'pièce',
      invoiced_quantity: 1,
      vat_rate: vats.first,
      position: 0,
    },
    {
      id: '019d1b3f-1420-753b-96b9-ce50c548a9c7',
      label: 'Machins',
      parent_id: '019d1b3f-1420-753b-96b9-ce50c548a9c8',
      quantity_for_single_unit_of_parent_line: 3,
      invoiced_quantity: 1,
      unit: 'pièce',
      position: 0,
    },
    {
      id: '019d1b3f-1420-753b-96b9-ce50c548a9e8',
      label: 'Panier du fermier',
      invoiced_quantity: 3,
      position: 1,
    },
    {
      id: '019d1b3f-1420-753b-96b9-ce50c548a9e9',
      parent_id: '019d1b3f-1420-753b-96b9-ce50c548a9e8',
      quantity_for_single_unit_of_parent_line: 0.2,
      gross_unit_price: 10,
      invoiced_quantity: 1,
      unit: 'kg',
      label: 'Poulet',
      vat_rate: vats.second,
      position: 1,
    },
    {
      id: '019d1b3f-1420-753b-96b9-ce50c548a9f0',
      parent_id: '019d1b3f-1420-753b-96b9-ce50c548a9e8',
      quantity_for_single_unit_of_parent_line: 1,
      gross_unit_price: 19,
      unit: 'pièce',
      invoiced_quantity: 1,
      label: 'Le plus gros potimaron du monde',
      vat_rate: vats.first,
      position: 0,
      discounts_attributes: [
        {
          name: 'promo 1',
          raw_value: -1,
          applicability: 'on_base',
        },
        {
          name: 'promo 2',
          percent: -0.05,
          applicability: 'on_base',
        },
      ],
      fees_attributes: [
        {
          name: 'frais de livraison',
          raw_value: 2,
          applicability: 'on_base',
        },
        {
          name: 'eco participation',
          percent: 0.1,
          applicability: 'on_base',
        },
      ],
    },
    {
      id: '019d1b3f-1420-753b-96b9-ce50c548a9f1',
      parent_id: '019d1b3f-1420-753b-96b9-ce50c548a9e8',
      label: 'Assortiment de baies',
      unit: 'poignée',
      invoiced_quantity: 1,
      quantity_for_single_unit_of_parent_line: 3,
      vat_rate: vats.second,
      position: 2,
    },
    {
      id: '019d20c1-5778-7331-a649-f5449db0fe8a',
      parent_id: '019d1b3f-1420-753b-96b9-ce50c548a9f1',
      quantity_for_single_unit_of_parent_line: 2,
      gross_unit_price: 0.85,
      invoiced_quantity: 1,
      unit: 'pièce',
      label: 'Myrtille',
      vat_rate: vats.third,
      position: 0,
    },
    {
      id: '019d1b3f-1420-753b-96b9-ce50c548a9f2',
      parent_id: '019d1b3f-1420-753b-96b9-ce50c548a9f1',
      quantity_for_single_unit_of_parent_line: 1,
      gross_unit_price: 0.63,
      invoiced_quantity: 1,
      unit: 'pièce',
      label: 'Mûre',
      vat_rate: vats.third,
      position: 1,
    },
    {
      id: '019d1b3f-1420-753b-96b9-ce50c548a9c2',
      label: "Location chambre d'hotel nuit",
      invoiced_quantity: 2,
      gross_unit_price: 75.0,
      vat_rate: vats.third,
      position: 0,
    },
    {
      id: '019d1b3f-1420-753b-96b9-ce50c548a9c3',
      parent_id: '019d1b3f-1420-753b-96b9-ce50c548a9c2',
      label: 'Petit déjeuner',
      invoiced_quantity: 2,
      gross_unit_price: 13.5,
      vat_rate: vats.second,
      position: 1,
    },
    {
      id: '019d1b3f-1420-753b-96b9-ce50c548a9c4',
      parent_id: '019d1b3f-1420-753b-96b9-ce50c548a9c2',
      label: "Service d'étage",
      invoiced_quantity: 1,
      gross_unit_price: 30.0,
      vat_rate: vats.third,
      position: 2,
    }
  ]
)

D::Uneek::Quote.create!(transaction_lines_attributes: [
    {article: article, invoiced_quantity: 1}
  ]
)

puts "finished"
