module Dynamic
  module RecipientInfo
    module PhoneNumber
      extend ActiveSupport::Concern
      extend Dynamic::Concern

      def self.after_included(klass, concern)
        proxify_concern(:__phone_recipient__, klass, concern, mandatory: [:recipient])

        c = klass.const.__phone_recipient_config

        c[:recipient] = concern.options.detect {|o| o.name == 'recipient_association'}&.value&.name
      end

      included do
        delegate *[
          :create_or_associate_recipient_phone,
          :number_changed?,
        ], to: :__phone_recipient__

        after_create :create_or_associate_recipient_phone
        after_update :create_or_associate_recipient_phone, if: :number_changed?
      end

      class Proxy <  Dynamic::Concern::Proxy

        def number_changed?
          @record.__phone__.number_previously_changed?
        end

        def create_or_associate_recipient_phone
          recipient_klass = @record.class.reflect_on_association(@config[:recipient].to_sym).klass
          recipient_phone = recipient_klass.create_with(
            info_attributes: {
              global_consent: false,
              npai: false,
              pressure: 0,
              source: 'CRM',
            },
          ).find_or_create_by(number: @record.__phone__.number)
          @record.update(recipient: recipient_phone)
        end

      end

    end
  end
end
