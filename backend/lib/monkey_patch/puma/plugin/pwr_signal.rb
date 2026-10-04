require 'puma/plugin'

# SIGINFO is not defined on linux, this plugin use SIGPWR instead

Puma::Plugin.create do
  def start(launcher)
    begin
      unless Puma.jruby?
        Signal.trap "SIGPWR" do
          launcher.instance_variable_get(:@log_writer).log("kill -s PWR")
          launcher.instance_variable_get(:@log_writer).log("signal received at #{DateTime.now.to_s}")
          launcher.thread_status do |name, backtrace|
            launcher.instance_variable_get(:@log_writer).log(name)
            backtrace.each { |bt| launcher.instance_variable_get(:@log_writer).log("  #{bt}") }
          end
        end
      end
    rescue Exception => e
      launcher.instance_variable_get(:@log_writer).log(e.message)
    end
  end
end
