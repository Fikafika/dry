if RUBY_ENGINE == 'opal'
  class HttpWithCrossDomain < HttpWithAbort

    def send(method, url, options, block)
      super(method, url, self.class.settings.merge(options), block) # TODO deep_merge?
    end

    include ::HTTP::Jwt

    class << self

      protected

      def has_jwt_token?(jwt_url)
        User.current.jwts.has_key?(jwt_url)
      end

      def retrieve_jwt_token(jwt_url)
        User.current.jwts[jwt_url]
      end

      def write_jwt_token(jwt_url, token)
        User.current.jwts[jwt_url] = token
      end

      private

      def build_jwt_request_sequence(method, url, options, block)
        super(method, url, self.settings.merge(options), block)
      end

    end

  end
end

class HttpWithCrossDomain

  def self.settings
    {
      xhrFields: {
        withCredentials: true,
      },
    }
  end

end

# TODO do_not_synchronize frontend/.bundle/gems/hyper-model-1.0.alpha1.5/lib/active_record_base.rb
