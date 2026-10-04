module Notification
  module Item
    module Bulk
      class DeleteAll < Base

        def icon
          'trash'
        end

        def title_i18n_key
          'crm.delete_records'
        end

      end
    end
  end
end
