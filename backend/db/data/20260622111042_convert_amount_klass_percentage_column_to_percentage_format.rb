# frozen_string_literal: true

class ConvertAmountKlassPercentageColumnToPercentageFormat < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      feature = schema.features.detect {|f| f.name == 'Dynamic::Amount::Feature'}
      next unless feature&.enabled
      concern = feature.concerns.detect {|c| c.name == 'Amount'}

      next unless concern.klass

      attr = concern.klass.attrs.detect {|a| a.name == 'percent'}
      attr.update!(locked: false)
      attr.update!(
        format: 'x100_percentage',
        format_options: {precision: 2},
      )
      attr.update!(locked: true)

      schema.load

      concern.klass.const.find_each do |a|
        a.update!(percent: a.percent / 100)
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
