require 'active_support/concern'

module HTTP::Jwt; extend ActiveSupport::Concern

  included do
    self::ACTIONS.each do |action|
      define_singleton_method(action) do |url, options = {}, &block|
        if options[:jwt_url]
          build_jwt_request_sequence(action, url, options, block)
        else
          super(url, options, &block)
        end
      end
    end
  end

  class_methods do
    def build_jwt_request_sequence(method, url, options, block)
      base_send_options = settings.merge(options).except(:jwt_url) # TODO deep_merge?
      jwt_send_options = base_send_options
      send_options = base_send_options.dup
      send_options[:xhrFields] = (send_options[:xhrFields] || {}).merge({ withCredentials: false })

      sequence = JwtRequestSequence.new

      if !has_jwt_token?(options[:jwt_url])
        promise = jwt_create_request(sequence, options[:jwt_url], jwt_send_options)
      end

      if promise
        promise = promise.then do
          request_with_jwt(sequence, options[:jwt_url], method, url, send_options)
        end
      else
        promise = request_with_jwt(sequence, options[:jwt_url], method, url, send_options)
      end

      promise = promise.fail do |previous_http|
        if previous_http.status_code == 401 && previous_http.url != options[:jwt_url]
          jwt_create_request(sequence, options[:jwt_url], jwt_send_options).then do
            request_with_jwt(sequence, options[:jwt_url], method, url, send_options)
          end
        else
          previous_http
        end
      end

      if block
        promise.always(&block)
        return sequence
      else
        return promise
      end
    end

    protected

    def has_jwt_token?(jwt_url)
      !!retrieve_jwt_token(jwt_url)
    end

    def retrieve_jwt_token(jwt_url)
      nil
    end

    def write_jwt_token(jwt_url)
    end

    private

    def jwt_create_request(sequence, jwt_url, options)
      http = new
      sequence.http = http
      http.post(jwt_url, options).then do |response|
        write_jwt_token(jwt_url, response.body)
      end
    end

    def request_with_jwt(sequence, jwt_url, method, url, options)
      authorization_headers = { 'Authorization' => "Bearer #{retrieve_jwt_token(jwt_url)}" }
      if options[:headers]
        options[:headers] = options[:headers].merge(authorization_headers)
      else
        options[:headers] = authorization_headers
      end
      http = new
      sequence.http = http
      http.send(method, url, options)
    end
  end

  class JwtRequestSequence

    attr_accessor :http

    def respond_to?(*args)
      self.http&.respond_to?(*args)
    end

    def method_missing(method, *args, **opts, &block)
      self.http.__send__(method, *args, **opts, &block)
    end

  end

end
