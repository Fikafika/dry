module Notification
  module Item
    class Copy < ::Notification::Item::Base
      include Hyperstack::Router::Helpers
      include ::Router::Resources

      def icon
        'copy'
      end

      def title
        I18n.t('activerecord.models.dynamic/copy/setting.one')
      end

      def actions_for_succeeded
        return unless result_record_ids&.any?
        BUTTON(class: 'btn btn-light') do
          I18n.t('crm.copy.notification.action.open_records')
        end.on(:click) do
          App.history.push(records_url)
        end
      end

      def records_url
        schema_id = request.params[:schema_id] || request.params[:schema]
        return '#' unless result_record_klass && schema_id
        route_key = result_record_klass.model_name.route_key
        "/crm/#{schema_id}/table/#{route_key}/last_search"
      end

      def result_record_klass
        record.data['result_record_type']&.safe_constantize if record.data.present?
      end

      def result_record_ids
        record.data['result_record_ids'] if record.data.present?
      end

    end
  end
end
