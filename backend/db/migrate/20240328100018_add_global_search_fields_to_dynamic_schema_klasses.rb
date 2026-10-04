class AddGlobalSearchFieldsToDynamicSchemaKlasses < ActiveRecord::Migration[6.0]
  def change
    change_table :dynamic_schema_klasses do |t|
      t.json :global_search_fields, default: []
    end
  end
end
