module Dynamic

  class Notification < ::Dynamic::Base
    define_api_path # /api/d/uneek/r__notifications

    module Feature
      def self.load_constants(schema)
        schema.const_reserved_klass("Notification", ::Dynamic::Notification)
      end
    end

    translates :title
    translates :body
    globalize_accessors

    def to_progress_event
      loadend = self.current && self.total && self.current >= self.total
      OpenStruct.new(loaded: self.current, total: self.total, type: ('loadend' if loadend))
    end

    def progress_info
      return unless self.total && self.total != 100 && (!indeterminate? || self.total != 0)
      "#{self.current} / #{self.total}"
    end

    def indeterminate?
      !(self.current && self.total && self.total != 0)
    end

    def start
      update(state: 'running')
    end

    def suspend
      update(state: 'suspended')
    end

    def continue
      start
    end

    def retry
      start
    end

    def cancel
      update(state: 'finished', final_state: 'canceled')
    end

    def close
      update(marked_as_read: true)
    end

    def self.unread
      where(marked_as_read: false, user_id: User.current.id).includes(translations: 1)
    end

    def self.not_shown
      where(marked_as_shown: false, user_id: User.current.id).includes(translations: 1)
    end

    def self.mark_all_as_read
      unread.update_all(
        marked_as_read: true,
        marked_as_shown: true,
      )
    end

  end


end
