# frozen_string_literal: true

class TouchSchemas < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      schema.touch
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
