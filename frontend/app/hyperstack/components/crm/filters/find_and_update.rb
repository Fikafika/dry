require 'components/crm/filters/normalization'

class Crm
  module Filters
    module FindAndUpdate
      include ::Crm::Filters::Normalization

      def extract_filter_from_search_query(search_query, filter_name)
        filters = search_query[:filters] rescue nil
        return find_filter(filters, filter_name)
      end

      def find_filter(o, filter_name)
        result = nil

        case o
        when ::Array
          o.each do |v|
            result = find_filter(v, filter_name)
            break if result
          end
        when ::Hash
          result = o[filter_name]
          unless result
            o.each do |k, v|
              next unless v.is_a?(::Array)
              result = find_filter(v, filter_name)
              if result && result.has_key?(filter_name)
                result = result[filter_name]
                break
              end
            end
          end
        end

        return result
      end

      def update_filter_in_search_query(search_query, filter_name, filter_value)
        search_query[:filters] ||= {}
        updated = update_filter(search_query[:filters], filter_name, filter_value)
        search_query[:filters] = add_filter(search_query[:filters], filter_name, filter_value) if !updated && !filter_value.nil?
        search_query[:filters] = simplify(search_query[:filters])
      end

      def update_filter(o, filter_name, filter_value)
        updated = false
        case o
        when ::Array
          to_delete = false
          o.each do |v|
            next unless v.is_a?(::Hash)
            if v[filter_name]
              if filter_value.nil?
                to_delete = true
              else
                v[filter_name] = filter_value
              end
              updated = true
            else
              v.values.each do |v_|
                updated = true if update_filter(v_, filter_name, filter_value)
              end
            end
          end
          if to_delete
            o.delete_if{|v| v[filter_name]}
          end
        when ::Hash
          if o[filter_name]
            if filter_value.nil?
              o.delete(filter_name)
            else
              o[filter_name] = filter_value
            end
          else
            o.values.each do |v|
              updated = true if update_filter(v, filter_name, filter_value)
            end
          end
        end
        return updated
      end

      def add_filter(filters, filter_name, filter_value)
        if filters['or']
          filters = {'and' => [filters]}
          filters['and'] << {filter_name => filter_value}
        elsif filters['and']
          filters['and'] << {filter_name => filter_value}
        else
          filters[filter_name] = filter_value
        end
        return filters
      end

    end
  end
end
