# frozen_string_literal: true

namespace :db do
  namespace :migrate do
    namespace :with_data do
      desc 'Run db:migrate:with and monitor ActiveRecord::ConcurrentMigrationError errors'
      task concurrent_safe: :environment do
        loop do
          Rake::Task['db:migrate:with_data'].reenable
          Rake::Task['db:migrate:with_data'].invoke
          break
        rescue ActiveRecord::ConcurrentMigrationError
          puts 'rake db:migrate:with_data already running in another container, sleeping for 2 seconds'
          sleep(2)
        end
      end
    end
  end
end
