class Dynamic::Record::Base

  default_scope -> {
    extending DifferentialUpdates::Relation
  }

  module DifferentialUpdates; extend ActiveSupport::Concern

    module Relation

      def differential_update(id, attributes)
        return true unless id == :all || attributes&.any?

        self.find_each do |record|
          record.differential_update(attributes)
        end

        return true
      end

    end

    included do

      def differential_update(attributes)
        return true unless attributes&.any?
        attributes = attributes.to_h.with_indifferent_access

        # currently support only one association to update
        assoc_key = attributes.keys.detect{|k| k.to_s.end_with?('_attributes') && attributes[k].is_a?(Hash) }
        assoc_name = assoc_key.to_s.gsub(/_attributes/, '')
        to_add = attributes.dig(assoc_key, :_add)
        to_remove = attributes.dig(assoc_key, :_remove)

        transaction do
          changed = false

          if to_add&.any?
            to_add&.each do |attrs|
              r = self.send(assoc_name).new(attrs)
              if r.save
                changed = true
              end
            end
          end

          if to_remove
            self.send(assoc_name).each do |r|
              records_to_destroy = []
              if to_remove == 'all' || to_remove.detect{|attrs| attrs.all?{|k,v| r.attributes[k] == v }}
                records_to_destroy << r
              end
              if records_to_destroy.any?
                self.send(assoc_name).destroy(records_to_destroy)
                changed = true
              end
            end
          end

          if changed
            touch
            save
          end
        end
        return true
      end
    end
  end
  include DifferentialUpdates
  extend DifferentialUpdates::Relation

  concerning :WhereQuery do

    included do

      scope :where_query, ->(query = {}.with_indifferent_access, time_zone = 'UTC', with_deleted = false) do
        query, time_zone, with_deleted = WhereQuery.extract_args(query, time_zone, with_deleted)
        if query.present?
          query = query.with_indifferent_access
          where(id: WhereQuery.ids_from_query(self, query, time_zone, with_deleted))
        else
          where
        end
      end

    end

    def self.extract_args(query, time_zone, with_deleted)
      if query.is_a?(String)
        parsed = Rison.parse(query)
        if parsed.is_a?(Array) # all args serialized in query
          parsed << 'UTC' if parsed.length == 1
          parsed << false if parsed.length == 2
          return parsed
        else
          return parsed, time_zone, with_deleted
        end
      else
        return query, time_zone, with_deleted
      end
    end

    def self.ids_from_query(klass, query, time_zone, with_deleted)
      es_query = build_es_query(klass, query, time_zone, with_deleted)
      return ids_from_es_query(klass, es_query)
    end

    def self.ids_from_es_query(klass, es_query)
      return [] unless es_query
      ids = []
      batch_size = 1000
      body = {query: es_query, size: batch_size, sort: {id: :asc},  _source: false}
      begin
        r = klass.__opensearch__.client.search(body: body, index: klass.index_name)
        hits = r.dig('hits', 'hits')
        next_ids = hits.map{|h| h['_id']}
        ids.concat(next_ids)
        body[:search_after] = hits.last.try(:[], 'sort')
      end while next_ids.any?
      return ids
    end

    def self.build_es_query(klass, query, time_zone, with_deleted)
      parts = [
        build_q_filter(query),
        build_table_filters(query, time_zone),
        build_chart_filters(klass, query, time_zone),
        build_with_deleted_filter(with_deleted),
        build_type_filter(klass),
      ].map(&:presence).compact
      return unless parts.any?
      return {bool: {filter: parts}}
    end

    def self.build_q_filter(query)
      return unless query[:q].present?
      {
        query_string: {
          query: "*#{sanitize_string_for_elasticsearch_string_query(query[:q])}*"
        }
      }
    end

    def self.sanitize_string_for_elasticsearch_string_query(str)
      Dynamic::Datatable::Elasticsearch.sanitize_string_for_elasticsearch_string_query(str)
    end

    def self.build_table_filters(query, time_zone)
      ::Dynamic::Filters::Converter.new(query.dig(:filters) || {}, {}, time_zone).to_es_query
    end

    def self.build_chart_filters(klass, query, time_zone)
      charts = ::Dynamic::Dashboard::Adapter.charts_from_query(klass, query)
      return unless charts.any?
      adapter = ::Dynamic::Dashboard::Adapter.new(klass, {search_query: query, time_zone: time_zone})
      chart_filters = []
      charts.each do |chart|
        chart_filters << adapter.filters_from_chart(chart) if chart.type != 'Table'
        chart_filters << adapter.exclusion_filters_from_chart(chart)
      end
      chart_filters.compact!
      return unless chart_filters.any?
      return {bool: {must: chart_filters}}
    end

    def self.build_with_deleted_filter(with_deleted)
      return with_deleted ? nil : { query_string: { query: "-_exists_:deleted_at" } }
    end

    def self.build_type_filter(klass)
      return if klass.nil? || klass == klass.base_class

      result = { query_string: { query: "type:\"#{klass.sti_name}\"" } }
      d = klass.descendants
      if d.any?
        f = [result]
        d.each do |k|
          f << { query_string: { query: "type:\"#{k.sti_name}\"" } }
        end
        result = {bool: {must: [{bool: {should: f}}]}}
      end

      return result
    end

  end

end
