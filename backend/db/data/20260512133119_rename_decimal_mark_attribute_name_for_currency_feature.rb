# frozen_string_literal: true

class RenameDecimalMarkAttributeNameForCurrencyFeature < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      feature = schema.features.detect {|f| f.name == 'Dynamic::Currency::Feature'}
      next unless feature
      klass = schema.klasses.detect {|k| k.name == 'Currency'}
      next unless klass
      decimal_attr = klass.attrs.detect {|a| a.name == 'decimal_mark'}
      decimal_attr.update!(human_name_fr: 'Séparateur decimal', human_name_en: 'Decimal separator') if decimal_attr
      name_attr = klass.attrs.detect {|a| a.name == 'name'}
      klass.update!(name_attribute: name_attr)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
