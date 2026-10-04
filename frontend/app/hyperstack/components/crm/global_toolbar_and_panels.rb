# backtick_javascript: true

class Crm
  class GlobalToolbarAndPanels < HyperComponent
    include Hyperstack::Router::Helpers
    include ::Router::Resources
    include Routes::Helpers
    include ::SchemaLoading
    include Crm::DataOpenPanel

    param :klass, default: nil

    after_update do
      show_or_hide_panels
    end

    after_mount do
      show_or_hide_panels
    end

    def show_or_hide_panels
      ['left', 'right'].each do |side|
        show = App.location.query[panel_param(side)].present?
        ::Element.find("##{side}-panel").modal(show ? 'show' : 'hide')
      end
      unhighlight unless a_panel_is_open?
    end

    def panel_param(side)
      "#{side[0]}p"
    end

    def a_panel_is_open?
      App.location.query[panel_param('left')].present? || App.location.query[panel_param('right')].present?
    end

    def highlight(element)
      # TODO
    end

    def unhighlight
      #TODO unhighlight
    end

    render(DIV) do # div needed for data-open-panel
      app_menu
      left_side_menu
      global_toolbar
      left_panel
      right_panel
      content
      global_toolbar_bottom
      additional_components
      notification_area
    end

    def app_menu
      LeftMenu()
    end

    def global_toolbar
      Toolbar(class:"toolbar bg-primary d-flex flex-row justify-content-between fixed-top border-bottom border-primary") do
        DIV(class: "d-flex align-items-center") do
          Toolbar::Button(text: '', icon_size: '2x', icon: 'bars', toggle: 'modal', target: "#left-menu", variant: 'primary')
          DIV(id: 'global-toolbar-left', class: 'd-flex align-items-center'){}
        end
        DIV(id: 'global-toolbar-center', class: 'd-flex align-items-center'){}
        DIV(class:"d-flex align-items-center flex-shrink-0") do
          DIV(id: 'global-toolbar-right', class: 'd-flex align-items-center'){}
          Notification::Icon(variant: 'primary')
          DIV(class: '') do
            Toolbar::UserButton(variant: 'primary')
          end
        end
      end
    end

    def left_side_menu
      ::Crm::ExpandingMenu(schema: schema, offset: 'toolbar-offset-top toolbar-offset-bottom-fixed', selected: selected_menu_item)
    end

    def selected_menu_item
      request.params[:mi] || request.location.pathname
    end

    def content
      DIV(class: "px-0 expanding-side-bar-offset toolbar-offset-top p-0 position-relative") do
        DIV(class: 'global-search-input') {}
        children.render
      end
    end

    def left_panel
      SidePanel(id: 'left-panel', side: 'left', size: 'md', backdrop: false, bg_color: 'transparent', class: 'd-flex', under_expanding_side_bar: true) do
        DIV(class: 'overflow-auto flex-fill' ) do
          Crm::RulePanel(klass: klass, path: App.location.query[panel_param('left')], side: 'left')
          Crm::Sheet(klass: klass, path: App.location.query[panel_param('left')], side: 'left').on(:change) do
            reload
          end
        end
      end
    end

    def right_panel
      SidePanel(id: 'right-panel', side: 'right', size: 'md', backdrop: false, bg_color: 'transparent', class: 'd-flex', under_expanding_side_bar: true) do
        DIV(class: 'overflow-auto flex-fill' ) do
          Crm::RulePanel(klass: klass, path: App.location.query[panel_param('right')], side: 'right')
          Crm::Sheet(klass: klass, path: App.location.query[panel_param('right')], side: 'right').on(:change) do
            reload
          end
        end
      end
    end

    def reload
      ::Element['.crm-index'].trigger(:reload)
    end

    def global_toolbar_bottom
      DIV(id: 'global-toolblar-bottom'){}
    end

    def additional_components # should be in crm component ?
      Crm::MailEditor()
      IFrameModal(id: "iframe-modal", portal: true)
    end

    def notification_area
      Portal(id: 'notification-area-portal', parentSelector: '.crm-portal-parent') do
        Notification::Area()
      end
    end

  end
end
