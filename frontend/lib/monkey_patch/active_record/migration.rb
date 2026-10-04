module MigratorWaitAdvisoryLock

  def run
    begin
      super
    rescue ActiveRecord::ConcurrentMigrationError
      log_concurrent_migration_error
      sleep duration_before_retry
      retry
    end
  end

  def log_concurrent_migration_error
    puts "ConcurrentMigrationError retry in #{duration_before_retry} secondes"
  end

  def duration_before_retry
    5
  end

  def migrate
    begin
      super
    rescue ActiveRecord::ConcurrentMigrationError
      log_concurrent_migration_error
      sleep duration_before_retry
      retry
    end
  end

end

ActiveSupport.on_load(:active_record) do
  ActiveRecord::Migrator.prepend(MigratorWaitAdvisoryLock)
end
