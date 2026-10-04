class CreateDynamicSchemaValidationAttributes < ActiveRecord::Migration[6.0]
  def change
    create_table :dynamic_schema_validation_attributes, id: :uuid do |t|
      t.belongs_to :schema, null: false, index: true, type: :uuid
      t.belongs_to :validation, null: false, index: true, type: :uuid
      t.belongs_to :attr, null: false, index: true, type: :uuid
      t.timestamps
      t.datetime :deleted_at, index: true
      t.index [:validation_id, :attr_id], where: 'deleted_at IS NULL', name: 'index_dynamic_schema_validation_attributes'
    end
  end
end
