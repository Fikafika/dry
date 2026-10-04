module Notification
  module Item
    class ModelDependency < ::Notification::Item::Base

      render { content }

      def explaination
        return unless success_count || error_count
        SPAN(class: 'pl-2 pr-2') do
          counts = [
            success_count ? I18n.t('notifications.success_count', count: success_count) : nil,
            error_count ? I18n.t('notifications.error_count', count: error_count) : nil,
          ].compact.join(', ')
          "(#{counts})"
        end
      end

      def success_count
        record.current
      end

      def error_count
        # TODO
      end

    end
  end
end
