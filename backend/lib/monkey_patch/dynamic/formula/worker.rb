require 'sidekiq/throttle_type'

ActiveSupport.on_load(:dynamic_formula_worker) do
  include ::Dynamic::Notification::WorkerWithNotification
  include ::Sidekiq::ThrottleType::Job
end
