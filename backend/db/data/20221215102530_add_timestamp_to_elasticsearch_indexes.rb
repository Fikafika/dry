class AddTimestampToElasticsearchIndexes < ActiveRecord::Migration[6.0]
  def change
    ::OpenSearch::Model.client.wait_for_server
    Dynamic::Schema.find_each do |schema|
      schema.klasses.with_deleted.each do |klass|
        old_index_name = klass.elasticsearch_get_index_name rescue nil
        next unless old_index_name&.split('-')&.length == 3 # d-uneek-contacts

        if klass.elasticsearch_mapping_field_count >= 1000
          klass.update_columns(compute_options_for_indexed_json: klass.compute_options_for_indexed_json)
          schema.unload
          schema.load
          klass.update_elasticsearch_index(true)
        else
          new_index_name = klass.send(:compute_elasticsearch_index_name)

          klass.update_column(:elasticsearch_mapping, klass.compute_elasticsearch_mapping) # in order to be sure it is correct

          klass.create_elasticsearch_index(new_index_name, nil, klass.elasticsearch_mapping)

          ::OpenSearch::Model.client.reindex({
            body: {
              source: {
                index: old_index_name,
              },
              dest: {
                index: new_index_name,
              }
            }
          })

          ::OpenSearch::Model.client.indices.delete(index: old_index_name)

          ::OpenSearch::Model.client.indices.update_aliases({
            body: {
              actions: [
                {
                  add: {
                    "index": new_index_name,
                    "alias": klass.elasticsearch_alias,
                  }
                }
              ]
            }
          })
        end
      end
    end
  end
end
