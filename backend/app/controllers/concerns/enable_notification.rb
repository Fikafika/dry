module EnableNotification

  def enable_notification
    old = Thread.current['notification_enabled']
    Thread.current['notification_enabled'] = true
    yield
  ensure
    Thread.current['notification_enabled'] = old
  end

end
