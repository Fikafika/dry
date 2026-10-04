module SidekiqThrottle

  def sidekiq_throttle_admin
    ::Sidekiq::Worker.throttle(:admin) do
      yield
    end
  end

  def sidekiq_throttle_user
    ::Sidekiq::Worker.throttle(:user) do
      yield
    end
  end

end
