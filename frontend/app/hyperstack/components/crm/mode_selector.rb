class Crm
  class ModeSelector < ::HyperComponent
    include Hyperstack::Router::Helpers

    param :variant, default: 'light-yiq', type: String
    param :mode
    param :is_dropdown, default: false, type: Boolean
    param :schema, default: {}
    fires :mode_selected

    def available_modes
      modes = [
        { name: 'table', icon: 'table' },
        { name: 'list', icon: 'id-card' },
        # { name: 'kanban', icon: 'table' },
        # { name: 'map', icon: 'map' },
      ]
      modes << { name: 'dashboard', icon: 'chart-pie' } if schema.has_feature_enabled?('Dynamic::Dashboard::Feature')
      modes
    end

    render do
      if is_dropdown
        Toolbar::Dropdown(
          text: I18n.t('crm.display'),
          icon: 'desktop',
          text_params: { class: 'ml-1 d-none d-md-inline-flex' },
          btn_params: { class: "btn btn-transparent-#{variant} shadow-none", title: I18n.t('crm.display') },
        ) do
          available_modes.each { |m| dropdown_mode_item(m) } if available_modes.length > 1
        end
      else
        DIV(class: 'btn-group') do
          available_modes.each { |m| button_mode_item(m) } if available_modes.length > 1
        end
      end
    end

    def dropdown_mode_item(m)
      Link('#', class: 'dropdown-item') do
        mode_item(m)
      end.on(:click) do |event|
        event.prevent_default
        mode_selected!(m[:name])
      end
    end

    def mode_item(m)
      I18n.t("crm.index.modes.#{m[:name]}")
    end

    def button_mode_item(m)
      Toolbar::Button(
        text: mode_item(m),
        icon: m[:icon],
        shape: '',
        class: mode == m[:name] ? 'active' : '',
        variant: variant
      ).on(:click) do |event|
        event.prevent_default
        mode_selected!(m[:name])
      end
    end
  end
end
