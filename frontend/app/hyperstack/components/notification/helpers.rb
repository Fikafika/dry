require 'active_support/concern'

module Notification
  module Helpers; extend ActiveSupport::Concern
    extend Router::Resources::Request::Helpers

    def notification_klass
      return unless schema_name
      "D::#{schema_name}::R::Notification".safe_constantize
    end

    def schema_name
      self.class.schema_name
    end

    def rerender_later_if_no_notification_klass
      if notification_klass.nil?
        @sync = false
        @retry ||= 0
        @retry += 1
        if @retry < 10
          $window.after(1) do
            sync
            mutate
          end
        end
      else
        @retry = 0
      end
    end

    class_methods do

      def schema_name
        return unless request
        (request.params[:schema] || request.params[:schema_id])&.classify_permalink
      end

    end

  end
end
