# frozen_string_literal: true

class AddAmountConcern < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      feature = schema.features.detect {|f| f.name == 'Dynamic::Amount::Feature'}
      next unless feature&.enabled
      amount_klass = schema.klasses.detect {|k| k.name == 'Amount'}
      concern = feature.concerns.create_with(
        human_name_fr: 'Montant',
        human_name_en: 'Amount',
        klass: amount_klass,
      ).find_or_create_by!(name: 'Amount')
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
