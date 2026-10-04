module Dynamic
  module RecipientInfo
    module Address; extend ActiveSupport::Concern

      included do
        before_create :create_address_info

        def create_address_info
          self.build_info(
            global_consent: false,
            tracking_pixel_consent: false,
            npai: false,
            pressure: 0,
            target: self,
            source: 'CRM',
          ) unless self.info
        end

      end

    end
  end
end