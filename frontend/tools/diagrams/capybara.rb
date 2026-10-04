ENV["RAILS_ENV"] ||= 'test'

require File.expand_path('../../config/environment', __dir__)
require File.expand_path('../../spec/helpers/capybara', __dir__)

Capybara.app_host = "http://frontend:5000"
Capybara.run_server = false
Capybara.current_driver = :chrome_headless

include Capybara::DSL

def page_load(path)
  page_exec(File.read(File.expand_path(path, __dir__)))
end

wait_until_top_level_component(500)
