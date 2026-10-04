# backtick_javascript: true

require 'hyper_resource'

module Dynamic

  class Base < ::HyperResource::Base

    include ::Icon

    class << self

      if RUBY_ENGINE == 'opal'
        # browser side

        def cable_native
          `ApiCable`
        end

        def feature
          nil
        end

        def api_id(resource)
          resource.id.to_s
        end

        def has_api_id?(resource, resource_id)
          resource.id.to_s == resource_id
        end

        private

        def to_permalink(s)
          return unless s
          s.underscore.gsub('/', '-')
        end

      else
        # server side

        def api_prefix
          "http://backend:3000#{ENV['APP_PATH_PREFIX']}/api"
        end

        def api_ws_path
          "ws://backend:3000#{ENV['APP_PATH_PREFIX']}/api/cable"
        end

        def api_options
          if ENV['DYNAMO_WS_PASSWORD']
            {
              ws_headers: {
                'AUTHORIZATION' => %Q[Basic #{::Base64.strict_encode64("#{ENV['DYNAMO_WS_USERNAME']}:#{ENV['DYNAMO_WS_PASSWORD']}")}],
              },
            }
          else
            {}
          end
        end

      end

      def api_path
        @api_path ||= [api_prefix, self.name.pluralize.underscore].join('/')
      end

      def schema_name
        self.name.split('::')[1].underscore
      end

      def define_api_path
        reserved_name = "r__#{self.name.gsub(/^Dynamic::/, '').gsub(/::Base$/, '').underscore.gsub('/', '__').pluralize}"

        define_singleton_method(:api_path) do
          @api_path ||= [api_prefix, 'd', self.name.start_with?('D::') ? schema_name : ':schema_name', reserved_name].join('/')
        end

        define_singleton_method(:member_params_key) do
          'base'
        end
      end

      def exceptions_for_update
        @exceptions_for_update ||= ['schema_name', 'schema_id']
      end

    end

    module Identification; extend ActiveSupport::Concern
      class_methods do
        def name_attribute
          'human_name'
        end
      end
    end; include Identification

  end

end
