module Dynamic
  module RecipientInfo
    module EmailAddress
      extend ActiveSupport::Concern
      extend Dynamic::Concern

      def self.after_included(klass, concern)
        proxify_concern(:__email_recipient__, klass, concern, mandatory: [:recipient])

        conf = klass.const.__email_recipient_config

        conf[:recipient] = concern.options.detect {|o| o.name == 'recipient_association'}&.value&.name
      end

      included do
        delegate *[
          :create_or_associate_recipient_email,
          :did_address_changed?,
          :update_recipient_consent,
          :did_consent_changed?,
          :update_recipient_npai,
          :did_npai_changed?,
        ], to: :__email_recipient__

        after_create :create_or_associate_recipient_email
        after_update :create_or_associate_recipient_email, if: :did_address_changed?
        before_update :update_recipient_consent, if: :did_consent_changed?
        before_update :update_recipient_npai, if: :did_npai_changed?
      end

      class Proxy < Dynamic::Concern::Proxy

        def did_address_changed?
          @record.__email__.address_previously_changed?
        end

        def did_consent_changed?
          @record.__email__.global_consent_changed? || @record.__email__.tracking_pixel_consent_changed?
        end

        def did_npai_changed?
          @record.__email__.npai_changed?
        end

        def create_or_associate_recipient_email
          recipient_klass = @record.class.reflect_on_association(@config[:recipient].to_sym).klass
          recipient_email = recipient_klass.find_by(address: @record.__email__.address)
          if recipient_email
            recipient_email.info&.update!(
              global_consent: @record.__email__.global_consent,
              tracking_pixel_consent: @record.__email__.tracking_pixel_consent,
              npai: @record.__email__.npai
            )
            @record.__email_recipient__.recipient = recipient_email
            @record.save!
          else
            @record.create_recipient(
              address: @record.__email__.address,
              info_attributes: {
                global_consent: @record.__email__.global_consent,
                tracking_pixel_consent: @record.__email__.tracking_pixel_consent,
                npai: @record.__email__.npai,
                pressure: 0,
                source: 'CRM',
              },
            )
          end
        end

        def update_recipient_consent
          if recipient&.info
            recipient.info.global_consent = @record.__email__.global_consent
            recipient.info.tracking_pixel_consent = @record.__email__.tracking_pixel_consent
          end
        end

        def update_recipient_npai
          recipient.info.npai = @record.__email__.npai if recipient&.info
        end

      end

    end
  end
end
