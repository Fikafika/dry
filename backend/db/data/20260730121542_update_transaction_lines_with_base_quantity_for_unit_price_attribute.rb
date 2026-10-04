# frozen_string_literal: true

class UpdateTransactionLinesWithBaseQuantityForUnitPriceAttribute < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      feature = schema.features.detect {|f| f.name == 'Dynamic::Transaction::Feature'}
      next unless feature&.enabled

      tl_klass = feature.concerns.detect {|c| c.name == 'Line::Base'}.klass
      next unless tl_klass

      tl_klass.attrs.create_with(
        type: 'Float',
        human_name_fr: 'Quantité de base du Prix Unitaire',
        human_name_en: 'Base quantity for Unit Price',
        locked: true,
      ).find_or_create_by!(name: 'base_quantity_for_unit_price')
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
