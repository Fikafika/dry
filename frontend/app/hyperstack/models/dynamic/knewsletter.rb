module Dynamic
  class Knewsletter < ::Dynamic::Base
    define_api_path

    class << self
      def feature
        'Dynamic::Knewsletter::Feature'
      end

      def model_name
        @model_name = ModelName.new(
          human_name: I18n.t('activerecord.models.dynamic/knewsletter.one'),
          plural_human_name: I18n.t('activerecord.models.dynamic/knewsletter.other'),
          route_key: 'knewsletters',
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

    class RecipientPath < Base;
      define_api_path
    end

    module Feature
      def self.load_constants(schema)
        schema.const_reserved_klass("Knewsletter::RecipientPath", ::Dynamic::Knewsletter::RecipientPath)
      end
    end

    module Link
    end

    module Newsletter
    end

    module NewsletterDelivery
    end

    module Visit
    end
  end
end
