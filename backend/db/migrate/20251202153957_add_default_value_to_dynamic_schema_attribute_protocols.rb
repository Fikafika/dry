class AddDefaultValueToDynamicSchemaAttributeProtocols < ActiveRecord::Migration[8.0]
  def change
    change_column_default :dynamic_schema_attributes, :protocols, 0
  end
end
