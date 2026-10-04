require 'components/debug_message'
require 'hyperstack/component/error_boundary'

class ErrorBoundary < HyperComponent
  def debug_message # redefined
    DebugMessage(error: @error, info: @info)
  end
end

# monkey patch hotloader in order to display DebugMessage
module Hyperstack
  class Hotloader
    module AddErrorBoundry
      def parse_display_and_clear_error
        DebugMessage(error: @err.is_a?(Array) ? @err[0] : @err)
      end
    end
  end
end
