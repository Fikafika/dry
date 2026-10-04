module Dynamic
  module RecipientInfo
    module Base; extend ActiveSupport::Concern

      included do
        after_update :update_email_consents, if: :saved_change_to_consents?
        after_update :update_email_npai, if: :saved_change_to_npai?

        def update_email_consents
          self&.target&.emails&.each do |e|
            e.update!(global_consent: self.global_consent, tracking_pixel_consent: self.tracking_pixel_consent)
          end
        end

        def update_email_npai
          self&.target&.emails&.each do |e|
            e.update!(npai: self.npai)
          end
        end

        private

        def saved_change_to_consents?
          saved_change_to_global_consent? || saved_change_to_tracking_pixel_consent?
        end

        def consent_or_npai_change?
          saved_change_to_global_consent? || saved_change_to_npai?
        end

      end

    end
  end
end
