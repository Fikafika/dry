# backtick_javascript: true

require 'active_support/concern'

module UrlHelper; extend ActiveSupport::Concern

  class_methods do

    def url_for(options)
      if options.is_a?(Hash)
        record = options[:record]
        record_id = options[:id] ? "/#{options[:id]}" : "/#{record&.id}"
        record_class = options[:klass] || record&.class
      elsif options.is_a?(Class)
        record_class = options
        record_id = nil
      else
        record = options if options.try(:id)
        record_class = options&.class
        record_id = "/#{record.id}" if record
      end

      if record_class.nil?
        `console.error(#{"Cannot build url_for(#{options.inspect})"})`
        return ''
      end

      schema = record_class.parent.name.demodulize.underscore
      klass = record_class.model_name.route_key

      mode = options[:mode]

      unless mode
        App.location.pathname =~ /\/crm\/#{schema}\/(table|list|map|dashboard)\//
        mode =  $1 || 'table'
      end
      if options[:action]
        unless [:show, :index].include?(options[:action].to_sym)
          action = '/' + options[:action]
        end
      end

      return "/crm/#{schema}/#{mode}/#{klass}#{record_id}#{action}"
    end

    def encode_url_params(params)
      return '' if params.nil?

      s = []

      case params
      when Array
        params.each do |name, value|
          s << encode_component_param(name, value)
        end
      when Hash
        params.each do |k, v|
          build_url_params(k, params[k], s)
        end
      end

      return s.join("&")
    end

    def decode_url_params(params_str)
      params_str = params_str&.gsub(/:\+/, ':%2B') # workaround search of phone number from open rainbow
      `$.deparam(#{params_str})`
    end

    private

    def build_url_params(prefix, obj, result = [])
      case obj
      when Array
        obj.each_with_index do |v|
          build_url_params(prefix + "[]", v, result);
        end
      when Hash
        obj.each do |k, v|
          build_url_params(prefix + "[#{k}]", obj[k], result);
        end
      else
        result << encode_component_param(prefix, obj)
      end
      return result
    end

    def encode_component_param(key, value)
      # Within a query component, the characters ";", "/", "?", ":", "@", "&", "=", "+", ",", and "$" are reserved. https://www.ietf.org/rfc/rfc2396.txt
      "#{key.to_s.gsub("&", '%26')}=#{value.to_s.gsub("&", '%26').gsub('?', "%3F").gsub('=', '%3D').gsub('+', '%2B')}"
    end

  end

  def url_for(options)
    self.class.url_for(options)
  end

  def interpolate_path(path, params)
    return path.gsub(/:([^\.\/]+)/) do |m|
      params[m[1..-1]]
    end
  end

  def encode_url_params(params)
    self.class.encode_url_params(params)
  end

  def decode_url_params(params_str)
    self.class.decode_url_params(params_str)
  end

  def add_param_to_url(url, param_name, param_value)
    return url unless param_value

    sep = url.include?('?') ? '&' : '?'
    return "#{url}#{sep}#{param_name}=#{param_value}"
  end

  def remove_param_from_url(url, param_name)
    path, query_string = url.split('?', 2)
    return url unless query_string

    updated_query = query_string.split('&').reject { |param| param.start_with?("#{param_name}=") }.join('&')

    return updated_query.empty? ? path : "#{path}?#{updated_query}"
  end
end
