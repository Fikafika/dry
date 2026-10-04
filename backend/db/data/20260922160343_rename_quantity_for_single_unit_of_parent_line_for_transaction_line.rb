# frozen_string_literal: true

class RenameQuantityForSingleUnitOfParentLineForTransactionLine < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      feature = schema.features.detect {|f| f.name == 'Dynamic::Transaction::Feature'}
      next unless feature&.enabled

      concern = feature.concerns.detect {|c| c.name == 'Line::Base'}
      next unless concern&.klass

      invoiced_quantity_attr = concern.klass.attrs.detect {|a| a.name == 'invoice_quantity'}
      invoiced_quantity_attr&.update!(comment: 'Peut être modifié automatiquement si le parent est un regroupement (voir Quantité par ligne Parent)')

      quantity_for_single_unit_of_parent_line = concern.klass.attrs.detect {|a| a.name == 'quantity_for_single_unit_of_parent_line'}
      quantity_for_single_unit_of_parent_line_attr&.update!(
        human_name_fr: "Quantité par ligne Parent",
        human_name_en: 'Quantity per Parent line',
        comment: 'Lorsque la ligne a pour parent un regroupement, la quantité sera calculé ainsi :\n quantité du parent * quantité par ligne Parent',
      )
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
