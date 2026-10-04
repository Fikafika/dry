def with_db_cache(version)

  def sql(q)
    ActiveRecord::Base.connection.select_values(q)
  end

  def connect_to(db_name)
    ActiveRecord::Base.connection.close
    ActiveRecord::Base.establish_connection({
      host: 'db',
      pool: ENV.fetch('RAILS_DATABASE_POOL'){ENV.fetch('RAILS_MAX_THREADS'){5}},
      adapter: 'postgresql',
      port: 5432,
      encoding: 'unicode',
      user: 'docker_postgres',
      password: nil,
      database: db_name,
    })
  end

  db_name = "app_test_#{version}"

  if sql("SELECT count(*) FROM pg_database WHERE datname = '#{db_name}'") == [1]
    puts "=================== using #{db_name} ==================="
    unless sql("SELECT count(*) FROM pg_database WHERE datname = 'another_database'").first > 0
      sql("CREATE DATABASE another_database")
    end
    connect_to('another_database')
    sql("SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datname = 'app_test' AND pid <> pg_backend_pid()")
    sql("DROP DATABASE IF EXISTS app_test")
    sql("CREATE DATABASE app_test WITH TEMPLATE #{db_name}")
    connect_to('app_test')
  else
    puts "=================== using app_test ==================="
    yield
    wait_for_sidekiq2
    sql("SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datname = 'app_test' AND pid <> pg_backend_pid()")
    sql("DROP DATABASE IF EXISTS #{db_name}")
    sql("CREATE DATABASE #{db_name} WITH TEMPLATE app_test")
  end

end
