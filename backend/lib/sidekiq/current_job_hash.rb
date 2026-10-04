# frozen_string_literal: true

# This middleware allows current job to know its run_at
# It is necessary for find duplicates running jobs

require 'sidekiq'
require 'sidekiq/job'

module Sidekiq
  module CurrentJobHash
    module Middleware

      class Server
        def call(job, msg, queue)
          Thread.current[:sidekiq_current_job_hash] = msg
          yield
        ensure
          Thread.current[:sidekiq_current_job_hash] = nil
        end
      end

      def self.configure
        ::Sidekiq.configure_server do |config|
          config.server_middleware do |chain|
            chain.add(::Sidekiq::CurrentJobHash::Middleware::Server)
          end
        end
      end

    end
  end
end
