module Dynamic
  module MailHosting
    module Worker
      class Sync
        include ::Sidekiq::Job

        sidekiq_options queue: :mail_hosting_sync

        def perform
          return if already_running?

          begin
            register_running
            Dynamic::MailHosting::SyncState.sync
          ensure
            deregister_running
          end
        end

        private

        def already_running?
          ::Sidekiq.redis do |r|
            r.get('mail_hosting_sync_job') == 'running'
          end
        end

        def register_running
          ::Sidekiq.redis do |r|
            r.set('mail_hosting_sync_job', 'running', ex: 7200)
          end
        end

        def deregister_running
          ::Sidekiq.redis do |r|
            r.del('mail_hosting_sync_job')
          end
        end
      end
    end
  end
end