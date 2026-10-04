# backtick_javascript: true

if RUBY_ENGINE == 'opal'
  require 'opal/jquery/http'

  class HttpWithAbort < HTTP

    def send(method, url, options, block)
      @method   = method
      @url      = url
      @payload  = options.delete :payload
      @handler  = block

      @settings.update options

      settings, payload = @settings.to_n, @payload

      %x{
        if (typeof(#{payload}) === 'string') {
          settings.data = payload;
        }
        else if (payload != nil) {
          settings.data = payload.$to_json();
          settings.contentType = 'application/json';
        }

        settings.url  = #@url;
        settings.type = #{@method.upcase};

        settings.success = function(data, status, xhr) {
          return #{ succeed `data`, `status`, `xhr` };
        };

        settings.error = function(xhr, status, error) {
          return #{ fail `xhr`, `status`, `error` };
        };
      }

      @ajax = `$.ajax(settings)`

      @handler ? self : promise
    end

    def abort
      `#{@ajax}.abort()` if @ajax
    end

  end

else

  # TODO
  class HttpWithAbort
  end

end
