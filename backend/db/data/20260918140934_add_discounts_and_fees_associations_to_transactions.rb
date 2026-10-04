# frozen_string_literal: true

class AddDiscountsAndFeesAssociationsToTransactions < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      feature = schema.features.detect {|f| f.name == 'Dynamic::Transaction::Feature'}
      next unless feature&.enabled

      base_concern = feature.concerns.detect {|c| c.name == 'Base'}
      next unless base_concern&.klass

      amount_concern = feature.concerns.detect {|c| c.name == 'AppliedAmount'}
      next unless amount_concern&.klass

      Dynamic::Transaction::Feature.create_applied_discount_and_fee_associations(base_concern.klass, amount_concern.klass)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
