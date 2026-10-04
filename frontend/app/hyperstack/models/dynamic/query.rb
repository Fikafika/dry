module Dynamic
  module Query
    class Base < ::Dynamic::Base
      define_api_path # /api/d/uneek/r__queries

      translates :human_name
      globalize_accessors

      attribute :params, type: Hash, default: {}

      def deep_dup
        r = self.dup
        r.attributes = self.attributes.deep_dup
        r
      end

      def self.clean_params(params)
        return self.clean_params!(params.deep_dup)
      end

      def self.clean_params!(params)
        result = params
        params.delete_if{|k, v| param_blank?(v) }
        params.keys.each do |k|
          params.delete(k) if param_blank?(params[k])
          next unless params[k].is_a?(::Hash)
          params[k] = clean_params!(params[k])
        end
        return params
      end

      def self.param_blank?(value)
        value.nil? || value == {} || value == ''
      end

    end

    class Saved < Base;
      define_api_path
    end
    class Current < Base; end

    class Relation < ::Dynamic::ReservedRelation; end

    module Feature; extend ActiveSupport::Concern
      def self.load_constants(schema)
        schema.const_reserved_klass("Query::Base", ::Dynamic::Query::Base)
        schema.const_reserved_klass("Query::Saved", ::Dynamic::Query::Saved)
        schema.const_reserved_klass("Query::Current", ::Dynamic::Query::Current)
      end
    end
  end

end
