# frozen_string_literal: true

class AddCurrencyIsoCodeToCountryFeature < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
    feature = schema.features.detect {|f| f.name == 'Dynamic::Country::Feature'}
    next unless feature
    feature.options.create!(
      name: 'currency_iso_code_attribute',
      human_name_fr: 'Attribut du code ISO de la monnaie',
      human_name_en: 'Iso code money attribute',
      type: 'String',
      coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
      value: nil
    )
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
