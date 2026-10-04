# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'

require File.expand_path('../config/environment', __dir__)

# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'

require 'sidekiq/batch/join'
require 'sidekiq/api'

require 'opensearch/rails/utils'
require 'database_cleaner'
require 'webmock/rspec'

require 'uneek_doc_gen/rspec'
require 'sidekiq/testing'

WebMock.allow_net_connect!(allow: 'opensearch_test')

OpenSearch::Model.client.wait_for_server

ActiveRecord::Migration.maintain_test_schema! rescue nil
ActiveRecord::Schema.verbose = false

Rails.application.reload_routes_unless_loaded # workaround lazy loading of rails 8. TODO remove with devise 5 ?

def clean(options = {})
  truncation_options = {}
  if options[:keep_schema]
    truncation_options[:only] = Dynamic::Schema.all.map {|s| s.klasses.map(&:const_table_name)}.flatten
    DatabaseCleaner.clean_with(:truncation, truncation_options)
    # FIXME clean opensearch documents (d_my_...)
  else
    DatabaseCleaner.clean_with(:truncation)
    tables = ActiveRecord::Base.connection.tables.select{ |t| t =~ /^d_/ }
    ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS #{tables.join(', ')} CASCADE") # TODO Dynamic::Schema.drop_dynamic_tables(true)
    unless options[:elasticsearch] == false
      # meh... find a way to OpenSearch::Model.client.indices.delete(index: '*')
      OpenSearch::Model.client.indices.get(index: '*').each_key do |index|
        next unless index.start_with?('d-')
        OpenSearch::Model.client.indices.delete(index: index)
      end
    end
  end
  Sidekiq.redis(&:flushdb)
end

def wait_for_sidekiq
  while Sidekiq::Stats.new.enqueued != 0
    sleep(0.2)
  end
end

def wait_for_sidekiq2
  loop do
    no_job = true
    queues = Sidekiq::Queue.all
    queues.each do |queue|
      queue.each do |job|
        no_job = false
        break
      end
    end
    break if no_job
    sleep 0.1
  end
  sleep 0.1
  loop do
    no_job = true
    queues = Sidekiq::Queue.all
    queues.each do |queue|
      queue.each do |job|
        no_job = false
        break
      end
    end
    break if no_job
    sleep 0.1
  end
end

RSpec.configure do |config|
  config.use_transactional_fixtures = false

  config.around(:each) do |example|
    wait_for_sidekiq unless example.metadata[:sidekiq] == false
    Sidekiq::Testing.disable! do
      example.run
    end
  ensure
    wait_for_sidekiq unless example.metadata[:sidekiq] == false
    Dynamic::Schema.loaded_schemas.values.map(&:unload) unless example.metadata[:keep_schema]
    clean(example.metadata)
  end

  config.before(:suite) do |suite|
    clean(suite.metadata)
  end

end
