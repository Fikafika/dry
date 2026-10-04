require 'sidekiq/throttle_type'
require_relative '../../../../app/models/dynamic/notification'
require_relative '../../../../app/models/dynamic/notification/worker_with_notification'

ActiveSupport.on_load(:dynamic_elasticsearch_worker) do
  include ::Dynamic::Notification::WorkerWithNotification
  include ::Sidekiq::ThrottleType::Job
end
