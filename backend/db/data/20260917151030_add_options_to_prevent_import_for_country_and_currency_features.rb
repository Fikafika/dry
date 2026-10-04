# frozen_string_literal: true

class AddOptionsToPreventImportForCountryAndCurrencyFeatures < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      country_feature = schema.features.detect {|f| f.name == 'Dynamic::Country::Feature'}
      if country_feature
        country_feature.options.create_with(
          human_name_fr: 'Mettre à jour les pays',
          human_name_en: 'Update countries',
          type: 'Boolean',
          value: !country_feature.enabled?
        ).find_or_create_by!(name: 'update_countries')
      end

      currency_feature = schema.features.detect {|f| f.name == 'Dynamic::Country::Feature'}
      if currency_feature
        currency_feature.options.create_with(
          human_name_fr: 'Mettre à jour les devises',
          human_name_en: 'Update currencies',
          type: 'Boolean',
          value: !currency_feature.enabled?
        ).find_or_create_by!(name: 'update_currencies')
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
