module Notification
  module Item
    class Merge < ::Notification::Item::Base
      include Hyperstack::Router::Helpers
      include ::Router::Resources
      include ::Crm::Routes::Helpers

      def icon
        'object-group'
      end

      def title
        I18n.t('activerecord.models.dynamic/merge/setting.one')
      end

      def actions_for_succeeded
        open_sheet_btn
      end

      def open_sheet_btn
        return unless result_record_klass && result_record_id
        A(class: 'btn btn-light', href: edit_url(result_record_klass, result_record_id), 'data-open-panel': 'right') do
          I18n.t('notifications.open_sheet')
        end
      end

      def result_record_klass
        record.data['result_record_type']&.safe_constantize if record.data.present?
      end

      def result_record_id
        record.data['result_record_id'] if record.data.present?
      end

      def actions_for_failed
        return unless record.final_state == "failed" || record.final_state == "canceled"
        open_setting_btn
      end

      def open_setting_btn
        return unless setting_record_id
        BUTTON(class: 'btn btn-light') { I18n.t('notifications.view_settings') }.on(:click) do
          App.history.push(edit_merge_setting_url)
        end
      end

      def edit_merge_setting_url
        schema_id = request.params[:schema_id] || request.params[:schema]
        return "/crm/#{schema_id}/merge_settings/#{setting_record_id}/edit"
      end

      def setting_record_klass
        record.data['record_type']&.safe_constantize if record.data.present?
      end

      def setting_record_id
        record.data['record_id'] if record.data.present?
      end
    end

  end
end
