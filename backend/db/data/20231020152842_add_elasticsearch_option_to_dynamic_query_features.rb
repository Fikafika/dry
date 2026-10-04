# frozen_string_literal: true

class AddElasticsearchOptionToDynamicQueryFeatures < ActiveRecord::Migration[6.0]
  def up
    ::OpenSearch::Model.client.wait_for_server
    Dynamic::Schema::Feature.where(name: 'Dynamic::Query::Feature').find_each do |f|
      f.dependency_order = 57
      f.save!(touch: false)
      next if f.options.detect{|o| o.name == 'elasticsearch_indices_already_created'}
      f.options.create!(
        name: 'elasticsearch_indices_already_created',
        human_name_en: 'Elasticsearch indices already created',
        human_name_fr: "Creation des index elasticsearch effectuée",
        type: 'Boolean',
        value: false,
      )
    end
    Dynamic::Schema.find_each do |s|
      next unless s.feature_enabled?('Dynamic::Query::Feature') && s.feature_enabled?('Dynamic::Elasticsearch::Feature')
      s.load
      s.const::R::Query::Saved.find_each do |q|
        q.__opensearch__.update_document
      end
    end
  end

  def down
  end
end
