# frozen_string_literal: true

class RemoveNoteAttributeFromTransactions < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      feature = schema.features.detect {|f| f.name == 'Dynamic::Transaction::Feature'}
      next unless feature&.enabled

      concern = feature.concerns.detect {|c| c.name == 'Line::Base'}
      next unless concern&.klass

      concern.klass.attrs.detect {|a| a.name == 'note'}&.destroy!
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
