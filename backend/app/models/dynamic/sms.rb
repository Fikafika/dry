module Dynamic
  module Sms

    URI_SMS_API = "#{ENV['SMS_API_PROTOCOL'] || 'https'}://#{ENV['SMS_API_HOST']}#{":#{ENV['SMS_API_PORT']}" if ENV['SMS_API_PORT']}/smses"

    def self.call_api(url, params={}, options={})
      faraday_opts = {
        headers: {}
      }
      faraday_opts[:headers]['Content-Type'] = options[:content_type] if options[:content_type].present?

      con = Faraday.new(faraday_opts) do |builder|
        if options[:basic_auth_name].present? && options[:basic_auth_pass].present?
          builder.request :authorization, :basic, options[:basic_auth_name], options[:basic_auth_pass]
        end
        if options[:access_token]
          builder.request :authorization, 'Bearer', options[:access_token]
        end
      end
      con.options.timeout = options[:timeout] if options[:timeout].present?

      case options[:type]
      when /POST/i
        response = con.post(url, params.to_json)
      when /PUT/i
        response = con.put(url, params.to_json)
      when /PATCH/i
        response = con.patch(url, params.to_json)
      else # GET
        response = con.get(url, params)
      end

      return nil unless response.success?
      return JSON.parse(response.body)
    end

    def self.parse_uri_with_json(uri)
      str_uri = uri.to_s + ".json"
      return URI.parse(str_uri)
    end
  end
end
