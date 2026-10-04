module Notification
  class List < HyperComponent
    include Helpers

    collect_other_params_as :other_params

    render{ content }

    def content
      if notification_klass
        DIV(class: 'list-group list-group-flush') do
          notifications.each do |n|
            Item.klass_from(n).insert_element(record: n)
          end
        end
      else
        DIV{}
      end
    end

    def notifications
      observe notification_klass.unread.order(id: :desc).all
    end

    # -------------------------------------------------------

    after_mount do
      sync
    end

    before_unmount do
      desync
    end

    def sync
      return unless notification_klass
      notifications.__cable__.subscribe
    end

    def desync
      return unless notification_klass
      notifications.__cable__.unsubscribe
    end

  end

end

