class AddFrozenTableToDynamicSchemaKlass < ActiveRecord::Migration[6.0]
  def change
    change_table :dynamic_schema_klasses do |t|
      t.boolean :frozen_table, default: false
    end
  end
end