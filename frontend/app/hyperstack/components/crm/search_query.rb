# backtick_javascript: true

class Crm
  class SearchQuery

    def initialize(str_or_hash, defaults = nil)
      @params = extract_hash(str_or_hash)
      @params = clean_search_query_params(@params)
      add_missing_keys(@params, defaults) if defaults
    end

    delegate :[], :[]=, :delete, :dig, :has_key?, :each, to: :@params

    def params
      @params
    end

    def delete_chart(chart_id)
      @params.delete(chart_id)
    end

    def reset(str_or_hash, defaults = nil)
      keys = @params.keys
      keys.each do |k|
        if k.start_with?('chart-')
          if @params[k].is_a?(Hash)
            @params[k].clear
          else
            @params.delete(k)
          end
        else
          @params.delete(k)
        end
      end

      h = extract_hash(str_or_hash)
      h = clean_search_query_params(h)
      h.each do |k, v|
        if k.start_with?('chart-')
          if v.is_a?(Hash)
            @params[k] ||= {}
            @params[k].merge!(v)
          else
            @params[k] = v
          end
        else
          @params[k] = v
        end
      end

      add_missing_keys(@params, defaults) if defaults
    end

    def reset_filters
      @params.delete(:filters) # TODO remove
      @params.delete(:q)

      @params.keys.each do |k|
        if k.start_with?('chart-') || k == 'table'
          value = @params[k]
          if value.is_a?(Hash)
            value.delete(:filters)
            if k.start_with?('chart-')
              value.delete(:exclusion_filters)
              value.delete(:contains)
              @params.delete(k) if value.empty?
            end
          else
            @params.delete(k)
          end
        end
      end
    end

    def reset_order
      @params.keys.each do |k|
        if k.start_with?('chart-') || k == 'table'
          if @params[k].is_a?(Hash)
            @params[k].delete(:order)
            @params.delete(k) if k.start_with?('chart-') && @params[k].empty?
          end
        end
      end
    end

    def dump
      rison_dump(reorder_params(@params))
    end

    private

    def extract_hash(str_or_hash)
      case str_or_hash
      when Hash
        return str_or_hash
      when String
        if str_or_hash.present?
          return  rison_parse(str_or_hash)
        else
          return {}
        end
      else
        {}
      end
    end

    def rison_parse(o)
      begin
        Rison.parse(o)
      rescue
        `console.error('fail to parse query', #{o})`
        {}
      end
    end

    def rison_dump(o)
      Rison.dump(o).gsub('+', '%2B')
    end

    def reorder_params(query)
      r = {}
      [
        "q",
        "filters",
      ].each do |k|
        next unless query.has_key?(k)
        r[k] = query[k]
      end
      query.each do |k, v|
        next if k == "q" || k == "filters"
        r[k] = query[k]
      end
      return r
    end

    def add_missing_keys(base, complement)
      complement.each do |k, v|
        if base.has_key?(k)
          if base[k].is_a?(Hash) && v.is_a?(Hash)
            add_missing_keys(base[k], v)
          end
        else
          base[k] = v.respond_to?(:deep_dup) ? v.deep_dup : v.dup
        end
      end
    end

    def clean_search_query_params(params)
      h = params
      h.each do |k,v|
        if k.start_with?('chart-')
          unless v.is_a?(Hash)
            params[k] = {}
            params[k]["filters"] = v
          end
        end
      end
      params
    end
  end
end
