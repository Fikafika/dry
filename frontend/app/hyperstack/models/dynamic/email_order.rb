module Dynamic
  module EmailOrder
    class Base < Base
      define_api_path
      has_many :types, class_name: 'Dynamic::EmailOrder::Type', inverse_of: :email_order

      class << self
        def feature
          'Dynamic::Communication::Feature'
        end

        def model_name
          @model_name = ModelName.new(
            human_name: I18n.t('activerecord.models.dynamic/email_order.one'),
            plural_human_name: I18n.t('activerecord.models.dynamic/email_order.other'),
            route_key: 'email_orders',
          )
        end

        def includes_for_load
          {
            translations: 1,
            types: {include: {translations: 1}},
          }
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

    class Type < Base
      define_api_path

      attribute :tag, type: String
      attribute :position, type: Integer
    end
  end
end
