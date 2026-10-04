class LayoutEvent
  @listeners = {}

  class << self
    def on(event_name, &block)
      @listeners[event_name] ||= []
      @listeners[event_name] << block
    end

    def emit(event_name, data = nil)
      return unless @listeners[event_name]
      @listeners[event_name].each { |block| block.call(data) }
    end

    def off(event_name, listener_id)
      return unless @listeners[event_name]
      @listeners[event_name].delete(listener_id)
      @listeners.delete(event_name) if @listeners[event_name].empty?
    end
  end
end