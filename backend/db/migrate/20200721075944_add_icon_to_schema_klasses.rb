class AddIconToSchemaKlasses < ActiveRecord::Migration[6.0]
  def change
    add_column :dynamic_schema_klasses, :icon, :string
  end
end
