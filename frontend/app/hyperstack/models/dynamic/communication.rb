module Dynamic
  class Communication < ::Dynamic::Base
    module Feature
      def self.load_constants(schema)
        schema.const_reserved_klass("EmailOrder::Base", ::Dynamic::EmailOrder::Base)
        schema.const_reserved_klass("EmailOrder::Type", ::Dynamic::EmailOrder::Type)
      end
    end

    module Email
    end

    module Phone
    end

    module Address
    end
  end
end
