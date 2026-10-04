module Dynamic
  module Export
    class Setting < Dynamic::Base
      define_api_path # /api/d/uneek/r__export__settings

      class << self

        def model_name
          @model_name = ModelName.new(
            human_name: I18n.t('activerecord.models.dynamic/export/setting.one'),
            plural_human_name: I18n.t('activerecord.models.dynamic/export/setting.other'),
            route_key: 'exports',
          )
        end

        class ModelName
          attr_reader :route_key

          def initialize(**options)
            @human_name = options[:human_name]
            @plural_human_name = options[:plural_human_name]
            @route_key = options[:route_key]
          end

          def human(**options)
            if options[:count].nil? || options[:count] <= 1
              return @human_name
            else
              return @plural_human_name
            end
          end
        end
      end

    end

    module Feature; extend ActiveSupport::Concern
      def self.load_constants(schema)
        schema.const_reserved_klass("Export::Setting", ::Dynamic::Export::Setting)
      end
    end
  end
end
