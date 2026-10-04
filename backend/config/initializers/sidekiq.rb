require 'sidekiq'
require 'sidekiq/api'
require 'sidekiq-cron'
require 'dynamic/sidekiq'
require 'sidekiq/paper_trail'
require 'sidekiq/throttle_type'
require 'sidekiq/current_job_hash'
require 'sidekiq/custom_signals'

require_relative '../../app/models/dynamic/notification/sidekiq_middleware'

if ENV.has_key?('SIDEKIQ_JOB_BACKTRACE')
  # Beware: backtraces can take 1-4k of memory in Redis each so large amounts of failing jobs can significantly increase your Redis memory usage.
  case ENV['SIDEKIQ_JOB_BACKTRACE']
  when 'true'
    # enabled
    backtrace = true
  when 'false'
    # disabled
    backtrace = false
  else
    # number of lines in backtrace
    backtrace = ENV['SIDEKIQ_JOB_BACKTRACE'].to_i
  end
  Sidekiq.default_job_options['backtrace'] = backtrace
end

Sidekiq.configure_server do |config|
  config.redis = {
    url: ENV.fetch('REDIS_URL') { 'redis://redis:6379/1' }
  }

  jobs = [
    {
      'name'  => 'Job grouping',
      'class' => 'ModelDependency::GroupingWorker',
      'cron'  => '*/1 * * * *',
    },
  ]

  if ENV['UNEEK_MAIL_SYNC_CRON'].present?
    jobs << {
      'name'  => 'Mail Hosting Sync',
      'class' => 'Dynamic::MailHosting::Worker::Sync',
      'cron'  => ENV['UNEEK_MAIL_SYNC_CRON'],
      'source' => 'schedule',
    }
  end

  Sidekiq::Cron::Job.load_from_array!(jobs)
end

Sidekiq.configure_client do |config|
  config.redis = {
    url: ENV.fetch('REDIS_URL') { 'redis://redis:6379/1' }
  }
end

::Sidekiq::PaperTrail::Middleware.configure
::Dynamic::Notification::SidekiqMiddleware.configure
::Sidekiq::ThrottleType::Middleware.configure
::Sidekiq::CurrentJobHash::Middleware.configure

::Sidekiq::CustomSignals.monkey_patch_cli # must be called after middlewares
