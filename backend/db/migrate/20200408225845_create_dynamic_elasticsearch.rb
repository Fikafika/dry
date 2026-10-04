class CreateDynamicElasticsearch < ActiveRecord::Migration[6.0]

  def change
    add_column :dynamic_schema_klasses, :options_for_indexed_json, :json, default: {}
    add_column :dynamic_schema_klasses, :elasticsearch_mapping, :json, default: {}
    add_column :dynamic_schema_klasses, :elasticsearch_updated_at, :datetime
  end

end
