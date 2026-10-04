# frozen_string_literal: true

class ReplaceElasticsearchFeatureWithOpensearch < ActiveRecord::Migration[6.0]
  def up
    Dynamic::Schema::Feature.transaction do
      Dynamic::Schema::Feature.where(name: 'Elasticsearch').update_all(name: 'OpenSearch')
    end
  end

  def down
    Dynamic::Schema::Feature.transaction do
      Dynamic::Schema::Feature.where(name: 'OpenSearch').update_all(name: 'Elasticsearch')
    end
  end
end
