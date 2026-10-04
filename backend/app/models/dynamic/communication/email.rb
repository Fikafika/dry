module Dynamic
  module Communication
    module Email
      extend ActiveSupport::Concern
      extend Dynamic::Concern

      def self.after_included(klass, concern)
        proxify_concern(:__email__, klass, concern, mandatory: [:address, :tag, :global_consent, :tracking_pixel_consent, :npai, :owner])

        c = klass.const.__email_config

        c[:address] = concern.options.detect{|o| o.name == 'address_attribute'}&.value&.name
        c[:tag] = concern.options.detect{|o| o.name == 'tag_attribute'}&.value&.name
        c[:global_consent] = concern.options.detect{|o| o.name == 'global_consent_attribute'}&.value&.name
        c[:tracking_pixel_consent] = concern.options.detect{|o| o.name == 'tracking_pixel_consent_attribute'}&.value&.name
        c[:npai] = concern.options.detect{|o| o.name == 'npai_attribute'}&.value&.name
        c[:owner] = concern.options.detect{|o| o.name == 'owner_association'}&.value&.name
      end

      class Proxy <  Dynamic::Concern::Proxy
      end
    end
  end
end
