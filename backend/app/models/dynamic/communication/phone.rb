module Dynamic
  module Communication
    module Phone
      extend ActiveSupport::Concern
      extend Dynamic::Concern

      def self.after_included(klass, concern)
        proxify_concern(:__phone__, klass, concern, mandatory: [:number, :tag, :owner])

        c = klass.const.__phone_config

        c[:number] = concern.options.detect{|o| o.name == 'number_attribute'}&.value&.name
        c[:tag] = concern.options.detect{|o| o.name == 'tag_attribute'}&.value&.name
        c[:owner] = concern.options.detect{|o| o.name == 'owner_association'}&.value&.name
      end

      class Proxy <  Dynamic::Concern::Proxy
      end
    end
  end
end
