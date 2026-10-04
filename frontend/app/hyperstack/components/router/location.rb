# backtick_javascript: true

module Hyperstack
  module Router
    class Location
      include ::UrlHelper

      # overide hyperstack implementation

      # this improve computation of query:

      def query
        return decode_search(search)
      end

      def add_params(params_to_add = {})
        {
          pathname: self.pathname,
          search: encode_search(self.query.merge(params_to_add)),
          hash: self.hash,
          state: self.state
        }
      end

      def remove_param(param_to_remove)
        {
          pathname: self.pathname,
          search: encode_search(self.query.reject{|k,v| k == param_to_remove }),
          hash: self.hash,
          state: self.state
        }
      end

      def encode_search(params)
        '?' + encode_url_params(params)
      end

      def decode_search(search)
        return {} if search.blank? || search == "?"
        Hash.new(decode_url_params(search[1..-1]))
      end

      def hostname
        `window.location.hostname`
      end

      def protocol
        @protocol ||= `window.location.protocol`.gsub(':', '')
      end

      def href
        `window.location.href`
      end

    end
  end
end



