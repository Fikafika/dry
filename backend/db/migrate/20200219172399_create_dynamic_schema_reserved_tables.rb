class CreateDynamicSchemaReservedTables < ActiveRecord::Migration[8.0]
  def change
    create_table :dynamic_schema_reserved_tables, id: :uuid do |t|
      t.string :klass_name, null: false, index: true
      t.string :table_name, null: false
      t.belongs_to :schema, null: false, index: true, type: :uuid
      t.timestamps
      t.datetime :deleted_at, index: true
    end
  end
end
