require 'components/notification/helpers'

module Notification
  class Area < HyperComponent
    include Helpers
    include WithThrottling

    param :duration, default: 8

    render do
      content
    end

    def content
      DIV(class: "notification-area toolbar-offset-top p-3 #{'d-none' unless notifications.any?}", "aria-live": "polite", "aria-atomic": true, style: {position: 'absolute', bottom: 0, right: 0, zIndex: '10000'}) do
        notifications.each do |n|
          Item.klass_from(n).insert_element(record: n, layout: 'toast', duration: duration, area: self)
        end
      end
    end

    def notifications
      return [] unless relation
      relation.select{|n| !n.marked_as_shown }
    end


    before_mount do
      @shown ||= {}
    end

    before_render do
      observe relation
    end

    after_render do
      rerender_later_if_no_notification_klass
      fix_buggy_auto_unmount
    end

    def fix_buggy_auto_unmount
      # why I can pass area to items without it being unmounted when item is unmounted ?
      ::Hyperstack::Internal::AutoUnmount.objects_to_unmount.delete(self)
    end

    after_mount do
      sync
    end

    before_unmount do
      # why it is unmounted all the time ? workaround:
      $window.after(0.5) do
        unless ::Element.find(".notification-area").length > 0
          desync
        end
      end
    end

    def sync
      return unless notification_klass
      return if @sync
      @sync = true
      relation.__cable__.subscribe
    end

    def desync
      return unless notification_klass
      return unless @sync
      @sync = false
      relation.__cable__.unsubscribe
    end

    def relation
      return unless notification_klass
      @relation ||= notification_klass.not_shown.order(id: :asc).all
    end

    def mark_as_shown(notification)
      notification.attributes[:marked_as_shown] = true
      @shown[notification.id] = true
      with_throttling(0.1) do
        ids = @shown.keys
        if ids.any?
          if notification_klass
            notification_klass.where(
              id: ids,
              marked_as_shown: false,
              user_id: User.current.id
            ).update_all(marked_as_shown: true).then do
              ids.each do |id|
                @shown.delete(id)
              end
            end
          else
            # notification_klass disappear due to schema reloading
          end
        end
      end
    end

  end
end

