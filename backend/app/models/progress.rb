# frozen_string_literal: true

class Progress

  attr_reader :errors
  attr_accessor :latency_of_current
  attr_accessor :latency_of_canceled

  def initialize
    @errors = []
    @current = fetch_current || 0
    @latency_of_current = 1.second
    @latency_of_canceled = 0.2.seconds
  end

  def before_finish(&block)
    @before_finish = block
  end

  def after_finish(&block)
    @after_finish = block
  end

  def start
  end

  def success
    return fix_action if wrong_action?
    assign_current if latency_of_current
    @before_finish&.call('success')
    commit_success!
    @after_finish&.call('success')
  end

  def fail
    return fix_action if wrong_action?
    assign_current if latency_of_current
    @before_finish&.call('fail')
    commit_fail!(errors)
    @after_finish&.call('fail')
  end

  def cancel
    assign_current if latency_of_current
    @before_finish&.call('cancel')
    commit_cancel!
    @after_finish&.call('cancel')
  end

  def finished?
  end

  def canceled?
    return false unless can_cancel?

    if latency_of_canceled
      if @check_canceled_after && Time.now < @check_canceled_after
        return @canceled
      end

      @check_canceled_after = Time.now + latency_of_canceled
    end

    @canceled = fetch_canceled
    return @canceled
  end

  def suspended?
    return false unless can_suspend?

    if latency_of_canceled
      if @check_suspended_after && Time.now < @check_suspended_after
        return @suspended
      end

      @check_suspended_after = Time.now + latency_of_canceled
    end

    @suspended = fetch_suspend
    return @suspended
  end

  def current=(v)
    if latency_of_current
      if @update_current_after && Time.now < @update_current_after
        @current = v
        return @current
      end

      @update_current_after = Time.now + latency_of_current
    end

    commit_current!(v)
    @current = fetch_current
  end

  def current
    @current || fetch_current || 0
  end

  def total=(v)
  end

  def total
  end

  def without_latency(instant = true)
    if instant
      old_latency_of_current = self.latency_of_current
      old_latency_of_canceled = self.latency_of_canceled
      begin
        self.latency_of_current = nil
        self.latency_of_canceled = nil
        r = yield
      ensure
        self.latency_of_current = old_latency_of_current
        self.latency_of_canceled = old_latency_of_canceled
        r
      end
    else
      yield
    end
  end

  def data
    {}
  end

  protected

  def fetch_current
    nil
  end

  def assign_current
  end

  def commit_current!(v)
  end

  def commit_success!
  end

  def commit_fail!(errors)
  end

  def commit_cancel!
  end

  def can_cancel?
    false
  end

  def fetch_canceled
    false
  end

  def can_suspend?
    false
  end

  def fetch_suspend
    false
  end

  private

  def fix_action # fix action when worker success or fail but it has been canceled by user and there is a latency
    if canceled?
      cancel
    elsif suspended?
      if latency_of_current
        commit_current!(v)
      end
    end
  end

  def wrong_action?
    latency_of_canceled && without_latency { canceled? } # TODO implement wrong action when suspended and with latency
  end

end
