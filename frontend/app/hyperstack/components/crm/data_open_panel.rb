require 'active_support/concern'

class Crm
  module DataOpenPanel; extend ActiveSupport::Concern

    included do
      after_mount do
        init_links_for_open_panels
      end
    end

    def init_links_for_open_panels
      self.jq_node.on(:click, 'a[data-open-panel]') do |event|
        event.prevent_default
        link = ::Element.find(event.current_target)

        unless link.has_class?('dropdown-item')
          event.stop_propagation
        end

        side = link.attr('data-open-panel')

        if ['opposite', 'same'].include?(side)
          panel = event.target.closest('.side-panel')
          panel_side = panel.has_class?('side-panel-right') ? 'right' : 'left'

          if side == 'same'
            side = panel_side
          else
            side = panel_side == 'left' ? 'right' : 'left'
          end
        end

        Dynamic::Form.clear_cache_with_serialized_records
        open_panel(side, link.attr('href'))
        highlight(event.target.parent.parent)
      end
    end

    def open_panel(side, path)
      App.history.push(App.location.add_params(panel_param(side) => path))
      after(0.1) do
        ::Element[".side-panel-#{side}"].trigger(:focus)
      end
    end

  end
end
