require 'active_support/concern'
require 'components/env_title'

class Crm
  module CrmLayout; extend ActiveSupport::Concern # nota: can't be named Layout because there is a conflit with Layout in Crm::List::Item

    included do
      include Crm::DataOpenPanel
      include ::EnvTitle
    end

    def highlight(line)
    end

    def unhighlight
    end

    def layout_with_toolbar(args = {})
      global_toolbar
      left_panel
      right_panel

      ::Crm::ExpandingMenu(schema: schema, offset: 'toolbar-offset-top toolbar-offset-bottom-fixed', selected: selected_menu_item)

      DIV(class: "px-0 expanding-side-bar-offset toolbar-offset-top p-0 #{args[:class]}") do
        global_search_input
        yield
      end

      Crm::MailEditor()
      IFrameModal(id: "iframe-modal", portal: true)
      notification_area
    end

    def layout_without_toolbar(args = {})
      global_toolbar

      toolbar

      left_panel
      right_panel

      ::Crm::ExpandingMenu(schema: schema, offset: 'toolbar-offset-top toolbar-offset-bottom-fixed', selected: selected_menu_item)

      DIV(class: "px-0 expanding-side-bar-offset toolbar-offset-top p-0 #{args[:class]}") do
        global_search_input
        yield
      end

      notification_area # TODO outside of Crm?
    end

    def selected_menu_item
      request.params[:mi] || request.location.pathname
    end

    def global_search_input
    end

    def global_toolbar
      LeftMenu()
      Toolbar(class:"toolbar bg-primary d-flex flex-row fixed-top align-items-center justify-content-between border-bottom border-primary") do
        DIV(class: "d-flex align-items-center") do
          Toolbar::Button(text: '', icon_size: '2x', icon: 'bars', toggle: 'modal', target: "#left-menu", variant: 'primary')
          global_toolbar_title
          env_title
        end
        DIV(class:"d-flex align-items-center") do
          global_toolbar_menu_items
          Notification::Icon(variant: 'primary')
          DIV() do
            Toolbar::UserButton(variant: 'primary')
          end
        end
      end
    end

    def global_toolbar_title
    end

    def global_toolbar_menu_items
    end

    def toolbar
    end

    def left_panel
    end

    def right_panel
    end

    def show_or_hide_panels
      ['left', 'right'].each do |side|
        show = App.location.query[panel_param(side)].present?
        ::Element.find("##{side}-panel").modal(show ? 'show' : 'hide')
      end
      unhighlight unless a_panel_is_open?
    end

    def toggle_search_input
      ::Element['.search-input-field'].toggle_class('d-none')
    end

    def a_panel_is_open?
      App.location.query[panel_param('left')].present? || App.location.query[panel_param('right')].present?
    end

    private

    def notification_area
      Portal(id: 'notification-area-portal', parentSelector: '.crm-portal-parent') do
        Notification::Area()
      end
    end

  end
end
