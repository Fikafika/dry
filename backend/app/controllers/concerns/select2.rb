# frozen_string_literal: true

module Select2
  module ActiveRecord
    extend ActiveSupport::Concern

    included do
      attr_accessor :klass
      attr_accessor :params
    end

    def initialize(klass, params)
      @klass = klass.is_a?(Array) ? klass.first : klass
      @params = params
    end

    def to_json(*args)
      return {
        results: results.map{|r| convert(r)},
        #pagination: {
          #more: (results.total > per * page)
        #}
      }
    end

    def results
      @results ||= klass.where(where_from_filters).where(params[:where]&.permit! || {}).where("unaccent(LOWER(name)) LIKE unaccent(LOWER(?))", "%#{term}%").limit(100).all # TODO improve
    end

    private

    def convert(r)
      s = r.attributes;

      result = {
        id: s['id'],
        text: s[name_attribute].to_s,
        record: s
      }

      photo_id = s.dig(photo_attachment, 'attachment', 'signed_id')
      result[:photo_id] = photo_id if photo_id
      return result
    end

    def term
      params[:term]
    end

    def page
      params[:page] ? params[:page].to_i : 1
    end

    def per
      params[:per] ? params[:per].to_i : 10
    end

    def name_attribute
      klass.try(:name_attribute) || 'name'
    end

    def photo_attachment
      klass.try(:photo_attachment)
    end

    def where_from_filters
      result = {}
      filters = params[:filters].is_a?(String) ? Rison.parse(params[:filters]) : params[:filters]
      filters&.each do |k, v|
        if v.is_a?(Hash) && v['variable']
          value = params[:variables].try(:[], v['variable'])
        elsif v.is_a?(String)
          value = v
        end
        result[k] = value
      end
      return result
    end

  end

  module Elasticsearch
    extend ActiveSupport::Concern

    included do
      attr_accessor :klasses
      attr_accessor :params
    end

    def initialize(klasses, params)
      @params = params
      if klasses&.is_a?(Class)
        klasses = [klasses]
      end
      @klasses = klasses
      if klasses.nil? || klasses.empty?
        @klasses = all_klasses
      end
    end

    def to_json(*args)
      return {
        results: results.map{|r| convert(r)},
        pagination: {
          more: (results.total > per * page)
        }
      }
    end

    def results
      return OpenStruct.new(total: 0, map: []) unless klasses != [] && klasses
      return @results ||= do_search.page(page).per(per).results
    end

    def all_klasses(reload = false)
      return @all_klasses if @all_klasses and !reload
      if params[:schema_name]
        result = "D::#{params[:schema_name].classify_permalink}::DynamicRecord".safe_constantize&.subclasses || []
      else
        result = [] # TODO check this part for indexed users
      end

      @all_klasses = result
      return result
    end

    private

    def do_search
      if klasses.any? {|k| k.include?(Dynamic::Permission::OpenSearch::ControlledKlass)}
        user = ::User.current || ::UneekPermission::PredefinedReceiver::Public.instance
        Dynamic::Permission::OpenSearch::ControlledKlass.search_as(user, elasticsearch_query, klasses)
      else
        OpenSearch::Model.search(elasticsearch_query, klasses, ignore_unavailable: true)
      end
    end

    def convert(r)
      s = r._source;
      result_klass = klass_from_result(r)
      s[:type] ||= result_klass&.name
      result = {
        id: s['id'],
        text: s[name_attribute(result_klass)],
        record: s
      }
      photo_id = s.dig(photo_attachment(result_klass), 'attachment', 'signed_id')
      result[:photo_id] = photo_id if photo_id
      return result
    end

    def klass_from_result(r)
      return klasses_by_alias[r._index.gsub(/-\d+$/, '')]
    end

    def klasses_by_alias(reload = false)
      return @klasses_by_alias if @klasses_by_alias && !reload
      @klasses_by_alias = {}
      klasses.each do |k|
        @klasses_by_alias[k.index_name] = k # index_name is in fact an alias here
      end
      return @klasses_by_alias
    end

    def elasticsearch_query
      must = [
        { query_string: { query: term, fields: query_fields } },
        Dynamic::Filters::Converter.new(filters, params[:variables] || {}, params[:time_zone] || 'UTC').to_es_query,
        Dynamic::Record::Base::WhereQuery.build_with_deleted_filter(false),
      ]
      klasses.each do |k|
        must << Dynamic::Record::Base::WhereQuery.build_type_filter(k)
      end
      must = must.map(&:presence).compact
      result = { query: { bool: { must: must } } }
      sort_query = es_sort
      result[:sort] = sort_query if sort_query.present?
      result
    end

    def es_sort
      return [{params[:sort] => params[:dir] || 'asc'}] if params[:sort]
      default = association_default_order
      return [] unless default.present?
      default.map { |field, dir| {field => dir || 'asc'} }
    end

    def term
      return '*' unless params[:term].present?
      params[:term].to_s.split(' ').map{|t| "*#{sanitize_string_for_elasticsearch_string_query(t)}*"}.join(' ')
    end

    def query_fields
      result = []
      klasses.each do |k|
        if k.try(:global_search_fields)&.any?
          result.concat(k.global_search_fields)
        elsif k.try(:name_attribute)
          result << k.name_attribute
        end
      end
      return result
    end

    def page
      params[:page] ? params[:page].to_i : 1
    end

    def per
      params[:per] ? params[:per].to_i : 10
    end

    def name_attribute(klass)
      klass.try(:name_attribute) || 'name'
    end

    def photo_attachment(klass)
      klass.try(:photo_attachment)
    end

    def sanitize_string_for_elasticsearch_string_query(str)
      # Escape special characters
      # http://lucene.apache.org/core/old_versioned_docs/versions/2_9_1/queryparsersyntax.html#Escaping Special Characters
      escaped_characters = Regexp.escape('\\/+-&|!(){}[]^~*?:')
      str = str.gsub(/([#{escaped_characters}])/, '\\\\\1')

      # AND, OR and NOT are used by lucene as logical operators. We need
      # to escape them
      ['AND', 'OR', 'NOT'].each do |word|
        escaped_word = word.split('').map {|char| "\\#{char}" }.join('')
        str = str.gsub(/\s*\b(#{word.upcase})\b\s*/, " #{escaped_word} ")
      end

      # Escape odd quotes
      quote_count = str.count '"'
      str = str.gsub(/(.*)"(.*)/, '\1\"\3') if quote_count % 2 == 1

      str
    end

    def filters
      result = extract_filters_from_params
      return result if result.present?
      association_default_filters || result
    end

    def extract_filters_from_params
      return {} unless params[:filters]
      case params[:filters]
      when String
        return Rison.parse(params[:filters])
      else
        return params[:filters]
      end
    end

    def association_default_filters
      return unless enable_association_default_filters? && params[:association_name].present? && params[:owner_klass_name].present?
      owner_klass = params[:owner_klass_name].to_s.safe_constantize
      reflection = owner_klass&.reflect_on_association(params[:association_name].to_sym)
      reflection.try(:default_elasticsearch_filters, remove_variables: remove_variables_from_default_filters?).presence
    end

    def enable_association_default_filters?
      cast_bool(params[:enable_default_filters], true)
    end

    def cast_bool(v, fallback)
      case v
      when '1', 'true', true
        true
      when '0', 'false', false
        false
      else
        fallback
      end
    end

    def remove_variables_from_default_filters?
      cast_bool(params[:remove_variables_from_default_filters?], true)
    end

    def association_default_order
      return unless params[:association_name].present? && params[:owner_klass_name].present?
      owner_klass = params[:owner_klass_name].to_s.safe_constantize
      reflection = owner_klass&.reflect_on_association(params[:association_name].to_sym)
      reflection.try(:default_elasticsearch_order).presence
    end
  end
end
