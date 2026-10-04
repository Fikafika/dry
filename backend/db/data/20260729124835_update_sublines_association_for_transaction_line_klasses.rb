# frozen_string_literal: true

class UpdateSublinesAssociationForTransactionLineKlasses < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      feature = schema.features.detect {|f| f.name == 'Dynamic::Transaction::Feature'}
      next unless feature&.enabled

      tl_klass = feature.concerns.detect {|c| c.name == 'Line::Base'}.klass
      next unless tl_klass
      assoc = tl_klass.associations.detect {|a| a.name == 'sublines'}
      next unless assoc

      assoc.update!(dependent_destroy: false)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
