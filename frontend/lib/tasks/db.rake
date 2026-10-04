namespace :db do

  desc "waiting for sessions table to be created by backend"
  task :waiting_for_sessions_table => :environment do
    def table_exists?(table_name)
      !!ActiveRecord::Base.connection.data_source_exists?(table_name) rescue false
    end

    unless table_exists?('sessions')
      puts "waiting for sessions table"
    end

    timeout = DateTime.now + 1.minute
    while !table_exists?('sessions') && DateTime.now < timeout
      sleep 1
    end

    unless DateTime.now < timeout
      puts "timeout: sessions table doesn't exist"
      exit 1
    end
  end

end
