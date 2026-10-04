# frozen_string_literal: true

class AddConditionTypeToDynamicSchemaSequences < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema::Sequence.where.not(condition_attr_id: nil).update_all(condition_type: 1)
  end

  def down
  end
end
