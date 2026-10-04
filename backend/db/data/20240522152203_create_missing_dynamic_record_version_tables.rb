# frozen_string_literal: true

class CreateMissingDynamicRecordVersionTables < ActiveRecord::Migration[6.0]
  def up
    Dynamic::Schema.find_each do |schema|
      schema.klasses.with_deleted.find_each do |klass|
        klass.send(:create_version_table)
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
