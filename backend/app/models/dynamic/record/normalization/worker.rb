require 'sidekiq'
require 'sidekiq/batch'

module Dynamic
  module Record
    module Normalization
      class Worker
        include ::Sidekiq::Job
        include ::Dynamic::Worker::InBatches
        include ::Dynamic::Notification::WorkerWithNotification
        include ::Sidekiq::ThrottleType::Job

        sidekiq_options queue: 'default', retry: 0

        def perform(class_with_ids, options = {})
          in_batches_with_progress_and_deduplicated_jobs(class_with_ids, 'normalize records', options) do |klass, records|
            klass.normalize_all(records, options['attrs'])
          end
        end
      end
    end
  end
end
