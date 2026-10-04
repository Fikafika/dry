module Notification
  module Item
    class Export < ::Notification::Item::Base
      include Hyperstack::Router::Helpers
      include ::Router::Resources
      include ::Crm::Routes::Helpers

      def icon
        'file-export'
      end

      def title
        I18n.t('activerecord.models.dynamic/export/setting.one')
      end

      def actions_for_succeeded
        if record.data.present?
          result_export_download_path = record.data["result_export_download_path"]
          A(class: 'btn btn-light', type: "button", href: result_export_download_path) do
            I(class:"fa fa-download")
            I18n.t('shared.download')
          end
        end
      end
    end
  end
end