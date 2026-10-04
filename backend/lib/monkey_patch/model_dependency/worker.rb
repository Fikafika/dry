require 'sidekiq/throttle_type'

ActiveSupport.on_load(:model_dependency_worker) do
  include ::Dynamic::Notification::WorkerWithNotification
  include ::Sidekiq::ThrottleType::Job
end
