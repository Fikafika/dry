module Notification
  module Item
    module Bulk
      class SubmitAll < Base

        def icon
          'copy'
        end

        def title_i18n_key
          'crm.submit_all_records'
        end

      end
    end
  end
end