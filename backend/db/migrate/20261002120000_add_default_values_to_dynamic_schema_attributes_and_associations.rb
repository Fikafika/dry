class AddDefaultValuesToDynamicSchemaAttributesAndAssociations < ActiveRecord::Migration[8.0]
  def change
    change_table :dynamic_schema_attributes do |t|
      unless t.column_exists?(:default_value)
        t.json :default_value
      end
    end
    change_table :dynamic_schema_associations do |t|
      unless t.column_exists?(:default_value_record_refs)
        t.json :default_value_record_refs, default: []
      end
    end
  end
end
