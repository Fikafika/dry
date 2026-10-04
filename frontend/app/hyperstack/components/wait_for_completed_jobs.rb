# backtick_javascript: true

module WaitForCompletedJobs

  def wait_for_completed_jobs_options
    result = {}

    result.merge!({
      wait_for_completed_jobs: 2000,
      wait_for_completed_jobs_timeout: Proc.new do |callback|
        `console.warn('timeout of wait for completed jobs')`
        callback&.call
      end,
    })

    k = klass_to_refresh_in_elasticsearch
    result.merge!(klass_to_refresh_in_elasticsearch: k.name) if k

    return result
  end

  def klass_to_refresh_in_elasticsearch
    parts = App.location.pathname.split('/')
    return unless parts.length >= 5
    _, _, schema_name, _, route_key = parts
    return "D::#{schema_name.classify_permalink}".safe_constantize&.const_get_by_route_key(route_key)
  end

end
