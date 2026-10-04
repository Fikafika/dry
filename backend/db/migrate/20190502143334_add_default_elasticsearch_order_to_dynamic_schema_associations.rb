class AddDefaultElasticsearchOrderToDynamicSchemaAssociations < ActiveRecord::Migration[6.0]
  def change
    change_table :dynamic_schema_associations do |t|
      t.json :default_elasticsearch_order, default: [], if_not_exists: true
    end
  end
end
