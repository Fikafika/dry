# frozen_string_literal: true

class RenameConvertUntilFromTransactions < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      feature = schema.features.detect {|f| f.name == 'Dynamic::Transaction::Feature'}
      next unless feature&.enabled

      concern = feature.concerns.detect {|c| c.name == 'Base'}
      next unless concern&.klass

      attr = concern.klass.attrs.detect {|a| a.name == 'convert_until'}
      next unless attr

      attr.update!(locked: false)

      attr.update!(
        locked: true,
        name: 'convert_until',
        human_name_fr: "Générer jusqu'à",
        human_name_en: 'Generate until',
      )
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
