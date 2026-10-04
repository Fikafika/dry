# frozen_string_literal: true

# This middleware allows current job to register its jid in paper_trail

require 'sidekiq'

module Sidekiq
  module PaperTrail
    module Middleware

      class Server
        def call(job, msg, queue)
          ::PaperTrail.request(controller_info: {created_in: :job}) do
            yield
          end
        end
      end

      def self.configure
        ::Sidekiq.configure_server do |config|
          config.server_middleware do |chain|
            chain.add(::Sidekiq::PaperTrail::Middleware::Server)
          end
        end
      end

    end
  end
end
