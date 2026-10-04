# frozen_string_literal: true

require 'sidekiq'
require 'sidekiq/job'
require 'sidekiq/throttled'

module Sidekiq
  module ThrottleType
    module Middleware

      class Client
        def call(job_class_or_string, job, queue, redis_pool)
          options = job['args'].last
          if options.is_a?(Hash) && Thread.current['throttle_type']
            options['throttle_type'] = Thread.current['throttle_type'].to_s
          end
          yield
        end
      end

      class Server
        def call(worker, job, queue)
          options = job['args'].last
          throttle_type = options.is_a?(::Hash) ? options['throttle_type'] : nil
          if throttle_type
            ::Sidekiq::Job.throttle(throttle_type) do
              yield
            end
          else
            yield
          end
        end
      end

      def self.configure
        ::Sidekiq.configure_server do |config|
          config.server_middleware do |chain|
            chain.add(::Sidekiq::ThrottleType::Middleware::Server)
          end
        end
        ::Sidekiq.configure_client do |config|
          config.client_middleware do |chain|
            chain.add(::Sidekiq::ThrottleType::Middleware::Client)
          end
        end
      end

    end

    module Job

      THROTTLE_LIMITS = {
        'admin' => ((::Sidekiq.default_configuration[:concurrency] || 10) * 2/3).to_i,
        'user' => ((::Sidekiq.default_configuration[:concurrency] || 10) * 9/10).to_i,
        'default' => ((::Sidekiq.default_configuration[:concurrency] || 10) * 1/3).to_i,
      }.freeze

      def self.included(base)
        base.include(Sidekiq::Throttled::Job)
        Sidekiq::Throttled::Registry.add('Sidekiq::Job', **{
          concurrency: {
            limit: -> (*args) {
              options = args.last.is_a?(::Hash) ? args.last : {}
              THROTTLE_LIMITS[options['throttle_type'] || 'default']
            },
            key_suffix: -> (*args) {
              options = args.last.is_a?(::Hash) ? args.last : {}
              options['throttle_type'] || 'default'
            },
            ttl: 2.hour.to_i, # increased in order to reduce risk too much running workers
          }
        })
        base.sidekiq_throttle_as('Sidekiq::Job')
      end

    end

  end

  module Job
    def self.throttle(throttle_type)
      old = throttle_type
      begin
        Thread.current['throttle_type'] = throttle_type ? throttle_type.to_s : throttle_type
        yield
      ensure
        Thread.current['throttle_type'] = old
      end
    end
  end

end
