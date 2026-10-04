# frozen_string_literal: true

require 'dynamic_record'
require_relative '../concerns/hyper_resource_broadcast_update'
require_relative '../progress'

module Dynamic
 class Notification < ActiveRecord::Base
    self.abstract_class = true
    include Dynamic::Mount

    define_table do |t|

      t.string :icon
      t.string :title, translate: true
      t.text :body, translate: true

      t.integer :current, default: 0 # progress
      t.integer :total, default: 0

      t.boolean :can_cancel, default: false
      t.boolean :can_suspend, default: false
      t.boolean :can_retry, default: false

      t.integer :state
      t.integer :final_state

      t.boolean :marked_as_read, default: false
      t.boolean :marked_as_shown, default: false

      t.string :klass_name

      t.json :data
      t.json :data_errors

      t.belongs_to :user, type: :uuid
    end

    def self.drop_tables # for tests TODO should generalized in Dynamic::Mount
      ActiveRecord::Base.connection.execute('drop table "d_uneek_r_notification_translations"')
      ActiveRecord::Base.connection.execute('drop table "d_uneek_r_notifications"')
    end

    after_mount do
      safe_enum :state, {
        pending: 0,
        running: 1,
        suspended: 2,
        finished: 3,
      }

      safe_enum :final_state, {
        succeeded: 0,
        failed: 1,
        canceled: 2,
      }
    end

    def progress
      @progress ||= Progress.new(self)
    end

    def success!
      self.update(
        state: 'finished',
        final_state: 'succeeded',
        marked_as_read: false,
        marked_as_shown: false,
      )
    end

    def fail!(errors)
      self.update(
        state: 'finished',
        final_state: 'failed',
        data_errors: serialize_data_errors(errors),
        marked_as_read: false,
        marked_as_shown: false,
      )
    end

    def cancel!
      self.update(
        state: 'finished',
        final_state: 'canceled',
        marked_as_read: false,
        marked_as_shown: false,
      )
    end

    include HyperResourceBroadcastUpdate

    def broadcast_user_id
      self.user_id
    end

    private

    def serialize_data_errors(errors)
      return nil unless errors&.any?
      errors.map do |e|
        case e
        when ActiveModel::Errors
          e.to_hash
        when Exception
          {
            type: e.class.name,
            message: e.message,
            backtrace: e.backtrace,
          }
        when Hash
          e
        end
      end
    end

    module Feature; extend ::Dynamic::Feature

      def self.feature_attributes
        {
          # no dependency
          human_name_fr: 'Notifications',
          human_name_en: 'Notifications',
          mandatory: true, # TODO make it not mandatory
        }
      end

      def self.load(schema)
        ::Dynamic::Notification.mount(schema)
        return true
      end
    end

    class Progress < ::Progress

      attr_reader :notification

      def initialize(notification)
        @notification = notification
        super()
        @notification.data ||= {}.with_indifferent_access
      end

      def start
        @notification.update(
          state: :running,
          current: 0
        )
      rescue NameError => e
        reload_and_retry(e) ? retry : raise
      end

      def finished?
        @notification.state == 'finished'
      end

      def total=(v)
        @notification.update(total: v)
      rescue NameError => e
        reload_and_retry(e) ? retry : raise
      end

      def total
        @notification.total
      end

      def data
        @notification.data
      end

      protected

      def fetch_current
        @notification.current
      end

      def assign_current
        @notification.current = @current
      rescue NameError => e
        reload_and_retry(e) ? retry : raise
      end

      def commit_current!(v)
        @notification.update(current: v)
      rescue NameError => e
        reload_and_retry(e) ? retry : raise
      end

      def commit_success!
        @notification.success!
      rescue NameError => e
        reload_and_retry(e) ? retry : raise
      end

      def commit_fail!(errors)
        @notification.fail!(errors)
      rescue NameError => e
        reload_and_retry(e) ? retry : raise
      end

      def commit_cancel!
        @notification.cancel!
      rescue NameError => e
        reload_and_retry(e) ? retry : raise
      end

      def can_cancel?
        @notification.can_cancel?
      end

      def fetch_canceled
        data = @notification.data
        @notification.reload
        @notification.data = data
        return @notification.final_state == 'canceled'
      end

      def can_suspend?
        @notification.can_suspend?
      end

      def fetch_suspend
        data = @notification.data
        @notification.reload
        @notification.data = data
        return @notification.state == 'suspended'
      end

      def reload_and_retry(e)
        return false unless e.message.start_with?('Missing model')
        @retry ||= 0
        @retry += 1
        return false if @retry > 10
        Rails.logger.info "#{@notification.class.name} disappeared, reload it"
        Dynamic::Schema.load(@notification.class.name.split('::')[1])
        notification_klass = @notification.class.name.constantize
        @notification = notification_klass.find(@notification.id)
        return true
      end

    end
  end

end

