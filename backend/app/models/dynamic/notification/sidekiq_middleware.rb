module Dynamic
  class Notification
    module SidekiqMiddleware
      class Client

        def call(job_class_or_string, job, queue, redis_pool)
          options = job['args'].last
          if options.is_a?(Hash)
            notification = options.delete(:notification) || options.delete('notification')
            if !notification && Thread.current['notification_enabled']
              notification = create_notification(job_class_or_string, job)
            end
            if notification
              options['notification_type'] = notification.class.name
              options['notification_id'] = notification.id
            end
          end
          yield
        end

        private

        def create_notification(job_class_or_string, job)
          k = job_class_or_string.is_a?(Class) ? job_class_or_string : job_class_or_string.safe_constantize
          return k.try(:create_notification, job)
        end

      end

      class Server

        def call(worker, job, queue)
          progress = notification(job)&.progress
          options = job['args'].last
          options['progress'] = progress if options.is_a?(::Hash) && progress
          begin
            yield
          rescue => e
            raise unless progress
            progress.errors << e
            progress.fail
            nil
          end
        end

        def notification(job)
          options = job['args'].last
          return unless options.is_a?(Hash)
          notification_id = options.delete('notification_id')
          notification_type = options.delete('notification_type')
          return unless notification_id && notification_type
          result = notification_type.safe_constantize&.find_by_id(notification_id)
          if result.nil?
            schema_name = notification_type.split('::')[1]
            Dynamic::Schema.load(schema_name)
            result = notification_type.safe_constantize.find(notification_id)
          end

          result.data ||= {}.with_indifferent_access
          result.data[:job_args] = job['args'].deep_dup

          return result
        end

      end

      def self.configure
        ::Sidekiq.configure_server do |config|
          config.server_middleware do |chain|
            chain.add(::Dynamic::Notification::SidekiqMiddleware::Server)
          end
        end
        ::Sidekiq.configure_client do |config|
          config.client_middleware do |chain|
            chain.add(::Dynamic::Notification::SidekiqMiddleware::Client)
          end
        end
      end
    end
  end
end
