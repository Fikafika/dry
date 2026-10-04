module Notification
  module Item
    module Bulk
      class UpdateAll < Base

        def icon
          'pencil-alt'
        end

        def title_i18n_key
          'crm.update_records'
        end

      end
    end
  end
end
