# backtick_javascript: true

require 'hyper_resource'
require 'hyper_resource/base'
require 'hyper_resource/relation'

::HyperResource::Base.include Hyperstack::State::Observable

::HyperResource::Relation.include Hyperstack::State::Observable

::HyperResource::Relation::Count.include Hyperstack::State::Observable

::HyperResource::HTTP.settings = ::HttpWithCrossDomain.settings # enable cross domain for hyper_resources

::HyperResource::ActiveStorage.routes_prefix = "#{ENV['APP_PATH_PREFIX']}/api/files"


require 'as_deep_json'

::HyperResource::Base.include AsDeepJson
::HyperResource::Relation.include AsDeepJson::Collection


::HyperResource::Base.include(UpdatePositions)
::HyperResource::Relation.include(UpdatePositions::Relation)

module HyperResource
  class Base

    class << self

      def api_prefix
        @api_prefix ||= "#{ENV['APP_PATH_PREFIX']}/api"
      end

      def id_type
        'Uuid'
      end

      if RUBY_ENGINE == 'opal'
        def generate_uuid
          `uuidv7()`
        end
      else
        def generate_uuid
          UUID7.generate
        end
      end

      # TODO move in hyper_resource gem

      def interpolate_path_and_add_parameters(path, params, options = {})
        result = interpolate_path(path, params, options)
        result = add_parameters(result, params) unless options[:without_parameters]
        return result
      end

      def cable_native
        RUBY_ENGINE == 'opal' ? `ApiCable` : nil # TODO why App.cable is not available instead of exposed ApiCable ?
      end

    end

    def deep_json_permit?(k, options = {})
      true # permit all
    end
  end

  module EnumString; extend ActiveSupport::Concern

    class_methods do

      def enum(options = {})
        super
        attribute options.keys.first, type: String, possible_values: enum_values(options.keys.first)
      end

      def enum_values(k)
        values = send(k.to_s.pluralize)

        result = {}
        I18n.available_locales.each do |l|
          I18n.with_locale(l) do
            result[l] ||= []

            values.each do |v|
              result[l] << {value: v[0], label: self.human_attribute_value(k, v[0])}
            end
          end
        end
        return result
      end

    end

  end

end

HyperResource.configure do |config|
  config.find_or_create_by = :one_request
  config.current_user_id = Proc.new do
    User.try(:current)&.id # nota: frontend server doesn't respond to User.current
  end
end
