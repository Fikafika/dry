module Dynamic
  module Datatable
    class Adapter < Dynamic::Datatable::Elasticsearch

      def initialize(klass, params)
        params.permit!
        params = params.to_h.with_indifferent_access
        super(klass, params)
        es_query = es_query_from_search_query(klass, params)
        params[:es_query_for_global_and_columns_search] = es_query
        @summary_aggregator = Elasticsearch::SummaryAggregator.new(klass, @columns, params)
      end

      def elasticsearch_query
        query = super
        aggs = @summary_aggregator.build_aggs
        query.merge!(aggs) if aggs.any?
        query
      end

      def additional_data
        result = super
        return result unless @summary_aggregator.any?
        summaries = @summary_aggregator.extract(aggregations_from_response)
        result[:summaries] = summaries if summaries.any?
        result
      rescue => e
        Rails.logger.warn("SummaryAggregator extract error: #{e.message}")
        result
      end

      private

      def aggregations_from_response
        records.response['aggregations'] || {}
      end

      def es_query_from_search_query(klass, params)
        search_query = params[:search_query]
        return {} unless search_query
        search_query = Rison.parse(search_query) if search_query.is_a?(String)
        return {} unless search_query
        search_query = search_query.with_indifferent_access
        es_query = Dynamic::Record::Base::WhereQuery.build_es_query(klass, search_query, @time_zone, false)
        return {} unless es_query
        return { query: es_query }
      end

    end
  end
end