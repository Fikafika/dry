require 'components/toolbar'

module Notification
  class Icon < ::Toolbar::Button
    include Notification::Helpers

    render { content }

    def content
      if count && count > 0
        super.on(:click) do |e|
          e.prevent_default
          e.stop_propagation
          Panel.instance&.toggle
        end
      else
        DIV{}
      end
      Portal(id: 'notification-panel-portal', parentSelector: '.crm-portal-parent') do
        Notification::Panel()
      end
    end

    def icon
      'comment-alt'
    end

    def text
      count.to_s
    end

    # ----------------------------------------------------

    after_mount do
      sync
    end

    before_unmount do
      desync
    end

    def count
      return unless notification_klass
      observe notification_klass.unread.count
    end

    def sync
      return unless notification_klass
      return if @sync
      @sync = true
      count.__cable__.subscribe do
        next unless notification_klass # can disappear when schema is reloading
        count.reload do
          mutate
        end
        notification_klass.unread.all_from_cache&.stale!
      end
    end

    def desync
      return unless notification_klass
      return unless @sync
      @sync = false
      count.__cable__.unsubscribe
    end

  end

end
