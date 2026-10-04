class AddClickTypeToDynamicSchemaAttributes < ActiveRecord::Migration[6.0]
  def up
    add_column :dynamic_schema_attributes, :click_type, :integer
  end

  def down
    remove_column :dynamic_schema_attributes, :click_type
  end
end
