class Crm
  class ResizablePanel < HyperComponent
    param :width, default: 16
    param :min_width, default: 10
    param :max_width, default: 50

    fires :width_changed

    before_mount do
      @current_width = width
      @resize_state = nil
    end

    before_unmount do
      cleanup_resize_listeners
    end

    render do
      DIV(class: 'd-flex', style: { width: "#{@current_width}%" }) do
        DIV(class: 'rounded p-0 border flex-grow-1 overflow-auto') do
          children.each(&:render)
        end
      end
      resize_handle
    end

    def resize_handle
      DIV(
        class: 'resizable-panel-handle d-flex align-items-center justify-content-center flex-shrink-0',
        style: {
          width: '6px',
          cursor: 'col-resize',
          transition: 'background-color 0.2s'
        }
      ) do
        DIV(class: 'bg-secondary rounded', style: { width: '4px', height: '40px' })
      end.on(:mouse_down) do |e|
        start_resize(e)
      end.on(:mouse_enter) do |e|
        ::Element[e.current_target.to_n].add_class('bg-light')
      end.on(:mouse_leave) do |e|
        ::Element[e.current_target.to_n].remove_class('bg-light')
      end
    end

    private

    def start_resize(event)
      event.prevent_default
      event.stop_propagation
      container = ::Element[dom_node].parent
      panel = ::Element[dom_node]
      @resize_state = {
        start_x: event.page_x,
        start_width: @current_width,
        container: container,
        panel: panel
      }
      @mousemove_handler = ->(e) { handle_mousemove(e) }
      @mouseup_handler = ->(e) { handle_mouseup(e) }
      ::Element.find(`document`).on('mousemove.resizable_panel', &@mousemove_handler)
      ::Element.find(`document`).on('mouseup.resizable_panel', &@mouseup_handler)
    end

    def handle_mousemove(event)
      return unless @resize_state
      container_width = @resize_state[:container].width
      return if container_width.to_i == 0
      delta_x = event.page_x - @resize_state[:start_x]
      delta_percent = (delta_x.to_f / container_width) * 100
      new_width = @resize_state[:start_width] + delta_percent
      new_width = [[new_width, min_width].max, max_width].min
      @resize_state[:panel].css(width: "#{new_width}%")
      @resize_state[:last_width] = new_width
    end

    def handle_mouseup(event)
      return unless @resize_state
      cleanup_resize_listeners
      if @resize_state[:last_width]
        @current_width = @resize_state[:last_width].to_f
        width_changed!(@current_width)
      end
      @resize_state = nil
    end

    def cleanup_resize_listeners
      ::Element.find(`document`).off('.resizable_panel')
    end
  end
end