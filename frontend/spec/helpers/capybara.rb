require 'capybara/rspec'

ENV['RUNNER'] ||= 'chrome'

#Selenium::WebDriver.logger.level = :info #for debug chrome driver

Capybara.register_driver :chrome_headless do |app|
  options = ::Selenium::WebDriver::Chrome::Options.new.tap do |opts|
    opts.args << '--headless'
    opts.args << '--disable-gpu'
    opts.args << '--window-size=640,480'
    opts.args << '--no-sandbox'
  end

  options.add_option("goog:loggingPrefs", {browser: 'ALL'})

  Capybara::Selenium::Driver.new(app,
    browser: :remote,
    url: ENV['HUB_URL'],
    options: options
  )
end

require 'method_source'
require 'action_view/helpers/javascript_helper'

def mount(str = nil, &block)
  s = str.strip if str
  s = block_source_content(block) if block_given?
  return unless s
  s = Object.new.extend(ActionView::Helpers::JavaScriptHelper).escape_javascript(s)
  page.execute_script(%Q[Opal.eval("Test.instance.mount{#{s}}")])
end

def page_eval(str = nil, &block)
  s = str.strip if str
  s = block_source_content(block) if block_given?
  return unless s
  s = Object.new.extend(ActionView::Helpers::JavaScriptHelper).escape_javascript(s)
  return page.evaluate_script(%Q[Opal.eval("#{s}")])
end

def page_exec(str = nil, &block)
  s = str.strip if str
  s = block_source_content(block) if block_given?

  return unless s
  s = Object.new.extend(ActionView::Helpers::JavaScriptHelper).escape_javascript(s)
  page.execute_script(%Q[Opal.eval("#{s}")])
end

def block_source_content(block)
  special_char = '@@@@@'

  str = block.source.strip.gsub("\n", special_char)

  if str.index('do') && str.index('do') < (str.index('{') || Float::INFINITY)
    str = str.match(/do(.*)end/).try(:[], 1)
  else
    str = str.match(/\{(.*)\}/).try(:[], 1)
  end

  str.gsub!(special_char, "\n")

  str = str[0...str.index('}).to ')] if str.index('}).to ')

  str
end

require 'nokogiri'

def print_top_level_component
  html = find('[data-react-class="Hyperstack.Internal.Component.TopLevelRailsComponent"]', visible: false)['innerHTML']
  begin
    doc = Nokogiri::XML(html)
    puts doc.root.to_s
  rescue
    puts html
  end
end

def wait_until_top_level_component(time = 20)
  return if has_css?('[data-react-class="Hyperstack.Internal.Component.TopLevelRailsComponent"]', visible: false)
  Capybara.using_wait_time time do
    visit('/')
  end
  Capybara.using_wait_time time do
    find('[data-react-class="Hyperstack.Internal.Component.TopLevelRailsComponent"]', visible: false)
  end
end

def print_browser_logs(opts = {})
  silencers = opts[:silencers] || [
    /Warning\: Deprecated/,
    /Overwriting modules/, # quill
    /Error during WebSocket handshake/,
    /jquery3\-bootstrap/,
    /backtick\_javascript\: true\` \-\- \(file\)/,
    /user\.json/,
  ]

  logs = page.driver.browser.logs.get(:browser)

  logs = logs.select{|l| !silencers.detect{|s| l.to_s =~ s } }

  if opts[:levels]
    logs = logs.select{|l| l.level.in?(options[:levels])}
  end

  if opts[:tail]
    logs = logs.last(opts[:tail])
  end

  puts logs
end

def print_request_logs(remote_print = false)
  if remote_print
    page_exec do
      WebMock::RequestRegistry.instance.to_s.split("\n").each do |s|
        puts s
      end
    end
  else
    page_eval('WebMock::RequestRegistry.instance.to_s').split("\n").each do |s|
      puts s
    end
  end
end

def keep_previous_page
  Capybara.current_session.instance_variable_set(:@touched, false)
end


module DisplayScreenshotHtmlAndConsoleLogs

  def take_screenshot
    super

    puts "Top level component content:"
    puts ""
    print_top_level_component
    puts ""
    puts "Last console logs:"
    puts ""
    print_browser_logs(tail: 10)
    puts ""
    puts "Network requests:"
    puts ""
    print_request_logs
  end

  def image_path
    if ENV['DYNAMO_ROOT_PATH']
      super.gsub(/^\//, "file://#{ENV['DYNAMO_ROOT_PATH']}/")
    else
      super
    end
  end

end

ActiveSupport.on_load(:action_dispatch_system_test_case) do
  ActionDispatch::SystemTesting::TestHelpers::ScreenshotHelper.prepend(DisplayScreenshotHtmlAndConsoleLogs)

  module RSpec
    module Core
      module Formatters
        # @private
        class ExceptionPresenter

          def fully_formatted(failure_number, colorizer=::RSpec::Core::Formatters::ConsoleCodes)
            lines = fully_formatted_lines(failure_number, colorizer)

            screenshot_line = lines.index{|l| l.start_with?("     \e[31m\e]1337;File=name")}
            backtrace_line = lines.index{|l| l.start_with?("     \e[36m#")}

            if screenshot_line
              r = lines[0..screenshot_line]

              changed_lines = lines[screenshot_line + 1..backtrace_line -1].map{|l| l.gsub("\n\e[0m", "").gsub("     \e[31m", "     ")}

              r.concat(changed_lines)
              r.concat(lines[backtrace_line..])

              lines = r
            end

            lines.join("\n") << "\n"
          end

        end
      end
    end
  end

end
