ENV["RAILS_ENV"] ||= 'test'

require File.expand_path('../config/environment', __dir__)
require 'rspec/rails'
require 'helpers/capybara'

RSpec::Matchers.define_negated_matcher :not_change, :change

RSpec.configure do |config|

  config.before(:each, type: :system) do |ex|
    next if ex.metadata[:without_server]

    driven_by :chrome_headless

    Capybara.app_host = "http://frontend_test_server:5000"
    Capybara.run_server = false
  end

  config.filter_run_when_matching :focus

  config.before(:each) do |ex|
    next if ex.metadata[:without_server]
    wait_until_top_level_component(500)
    page_exec do
      WebMock.reset!
    end
  end
end
