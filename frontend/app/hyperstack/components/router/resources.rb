# backtick_javascript: true

module Router
  module Resources

    def Resources(target, options = {}, &block)
      Hyperstack::Internal::State::Mapper.observed! Hyperstack::Router::Location

      resource_id_key = /\(\/:(.*)\)/.match(target).to_a.last
      target = target.gsub(/\(\/.*\)/, '') if resource_id_key
      resource_id_key ||= 'id'

      opts = {}

      if block
        opts[:render] = lambda do |e|
          route_params = format_resource_params(e, resource_id_key)

          request = Request.new(route_params)
          request_history = ::Router::Resources.instance_variable_get(:@request_history) || []
          request_history.prepend request
          request_history.slice!(0, 20) if request_history.length > 20
          ::Router::Resources.instance_variable_set(:@request_history, request_history)
          ::Router::Resources.instance_variable_set(:@request, request) # assume there is one router with exclusive routes

          authentication = options[:authentication]
          authentication = true if authentication != false && authentication != 'optional'

          with_authentication(authentication) do
            yield(*route_params.values)
          end.to_n
        end
      end

      member_actions = ['edit', 'destroy', 'integrate']
      collection_actions = ['new']

      if options[:actions]
        if options[:actions][:member].is_a?(Array)
          member_actions.concat(options[:actions][:member])
        end
        if options[:actions][:collection].is_a?(Array)
          collection_actions.concat(options[:actions][:collection])
        end
      end
      Switch do
        React::Router::Route(opts.merge(path: "#{target}/:#{resource_id_key}/:action(#{member_actions.join('|')})", exact: true, strict: true))
        React::Router::Route(opts.merge(path: "#{target}/:action(#{collection_actions.join('|')})(\\?.*)?", exact: true, strict: true))
        React::Router::Route(opts.merge(path: "#{target}/:#{resource_id_key}([^?/]+)", exact: true, strict: true))  # prevent ? to be matched
        React::Router::Route(opts.merge(path: "#{target}([^?/]+)(\\?.*)?", exact: true, strict: true)) # prevent ? to be matched
        React::Router::Route(opts.merge(path: target.to_n, exact: true))
      end
    end

    def format_resource_params(e, resource_id_key)
      result = format_params(e)
      result[:match].params[:action] = action_from_params(result[:match].params, resource_id_key)
      return result
    end

    def action_from_params(params, resource_id_key)
      return params[:action] if params[:action]
      return params[resource_id_key.to_sym].present? ? 'show' : 'index'
    end

    # TODO not generic enough
    def with_authentication(authentication = true)
      if authentication
        if authentication == 'optional'
          SignInModal::Optional() do
            yield
          end
        else
          SignInModal::Required() do
            yield
          end
        end
      else
        SignInModal() do
          yield
        end
      end
    end

    def RouteWithRequest(path, options = {})
      Route(path, options) do |match, location|
        request = Router::Resources::Request.new(match: match, location: location)
        request.params[:action] = options[:action] || 'show'
        ::Router::Resources.instance_variable_set(:@request, request)
        yield(match)
      end
    end

    class Request

      def initialize(path_or_options = {})
        if path_or_options.is_a?(String)
          @match = match_from_path(path_or_options)
          @location = location_from_path(path_or_options)
        else
          @match = path_or_options[:match]
          if @match.params.has_key?('0')
            # extract query from params 0
            query_string = @match.params['0'].to_s.gsub(/^\?/, '')
            query = Hash.new(`$.deparam(query_string)`)
            @match.params.merge!(query)
            `delete #{@match.params}.native['0']`
          end
          @location = path_or_options[:location]
        end
      end

      def match
        @match
      end

      def location
        @location
      end

      def params
        @params ||= Params.new(self)
      end

      class Params

        def initialize(request)
          @request = request
        end

        def has_key?(k)
          @request.match&.params&.has_key?(k) || @request.location&.query.has_key?(k)
        end

        def [](k)
          @request.match&.params[k] || @request.location&.query[k]
        end

        def []=(k, v)
          return v unless @request.match&.params
          @request.match.params[k] = v
        end

        def each
          @request.match&.params&.each do |k, v|
            yield(k, v)
          end
          @request.location&.query&.each do |k, v|
            yield(k, v)
          end
        end

        def to_h
          (@request.location&.query || {}).merge(@request.match&.params&.to_h)
        end

      end

      module Helpers; extend ActiveSupport::Concern

        class_methods do
          def request
            ::Router::Resources.instance_variable_get(:@request)
          end

          def request_history
            ::Router::Resources.instance_variable_get(:@request_history)
          end
        end

        def request
          ::Router::Resources.instance_variable_get(:@request)
        end

        def request_history
          ::Router::Resources.instance_variable_get(:@request_history)
        end
      end

      private

      ID_REGEXP = /(?:^\d+$)|(?:^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$)/

      def match_from_path(path) # TODO currently fake, find a way to call matchPath of react-router
        s = path.split('/')

        case s[3]
        when 'dashboards'
          case s[5]
          when 'charts' # crm/:schema/dashboards/:dashboard_id/charts/:id/:action
            id, action = id_and_action(s)
            params = {
              schema: s[2],
              dashboard_id: s[4],
              id: id,
              action: action,
            }
          else # crm/:schema/dashboards/:id/:action
            id, action = id_and_action(s)
            params = {
              schema: s[2],
              id: id,
              action: action,
            }
          end
        else # crm/:schema/table/:klass/:id/:action
          id, action = id_and_action(s)
          params = {
            schema: s[2],
            klass: s[4],
            id: id,
            action: action,
          }
        end

        return OpenStruct.new(params: params)
      end

      def id_and_action(splitted_path)
        last = splitted_path.last&.gsub(/\?.*/, '')
        id = last if last && last =~ ID_REGEXP
        action = id ? 'show' : last
        if action != 'show' && action != 'new'
          id = splitted_path[splitted_path.length - 2]
        end
        return id, action
      end

      def location_from_path(path)
        s = path.gsub(/.*\?/, '')

        return Hyperstack::Router::Location.new({
          pathname: path.gsub(/\?.*/, ''),
          search: s.present? ? "?#{s}" : nil ,
        }.to_n)
      end

    end


  end
end
