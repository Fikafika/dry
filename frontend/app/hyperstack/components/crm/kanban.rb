class Crm
  class Kanban < Crm::Index::Base

    param :column_settings, default: nil
    param :sprint_param, default: nil
    param :column_attribute, default: nil

    render(DIV, class: 'crm-index') do
      global_toolbar
      redirect_to_index_with_a_right_panel_if_show_or_edit_record

      Crm::Kanban::View(
        relation: relation,
        column_states: column_states,
        column_settings: column_settings,
        column_attribute: column_attribute,
        sprint_param: sprint_param,
        reload: @reload,
      ).on(:drop_column) do |params|
        @column_settings = params
        save_column_setting(@column_settings)
      end.on(:toggle_column) do |col_states_params|
        @column_states = col_states_params
        kanban_query[:column_states] = col_states_params
        update_query_record
        App.history.replace(search_url(klass, @search_query, additional_params_for_search))
      end
      setting_modal
      edit_query_dialog
    end

    def dynamic_layout
      observe Dynamic::Layout.with_action('index').where(schema_id: schema.name, klass_name: klass.name).includes(elements: 1).find(layout_id)
    end

    def save_column_setting(column_settings)
      layout = dynamic_layout
      if layout.loaded?
        perform_column_save(layout, column_settings)
      else
        layout.load do
          perform_column_save(dynamic_layout, column_settings)
        end
      end
    end

    def perform_column_save(layout, column_settings)
      element = layout.elements.detect{ |e| e.component == 'Crm::Kanban' }
      if element&.component_params
        component_params = element.component_params.merge(column_settings: column_settings)
        layout.update(
          elements_attributes: [
            {
              id: element.id,
              component_params: component_params
            }
          ]
        ).then do |response|
          Dynamic::Layout.update_cache([:first, :all, :find])
        end
      end
    end

    def column_states
      @search_query.dig(:kanban, :column_states)
    end

    def init_search_query_defaults
      kanban_query[:column_states] = @column_states
    end

    def kanban_query
      @search_query ||= {}
      @search_query[:kanban] ||= {}
      return @search_query[:kanban]
    end

    def setting_modal
      Crm::Kanban::Setting::Modal(
        id: "edit-kanban-modal",
        size: 'md',
        klass: klass,
        schema: schema,
        dynamic_layout: dynamic_layout,
        column_settings: @column_settings,
      ).on(:confirm) do
        kanban_query[:column_states] = nil
        update_query_record
        App.history.replace(search_url(klass, @search_query, additional_params_for_search))
      end
    end

    def setting_panel
      Crm::Kanban::Setting::Panel(klass: klass, schema: schema, dynamic_layout: dynamic_layout, layout_id: layout_id).on(:save_setting) do
        kanban_query[:column_states] = nil
        update_query_record
        App.history.replace(search_url(klass, @search_query, additional_params_for_search))
      end
    end

    def global_toolbar_right
      Portal(id: 'global-toolbar-right') do
        GroupDrop(variant: 'primary') do
          Toolbar::Button(target: new_url(klass), text: I18n.t('shared.new'), icon: 'plus', is_flex: true, "data-open-panel": 'right', variant: 'primary')
          Toolbar::Button(text: I18n.t('shared.refresh'), icon: 'redo', is_flex: true, variant: 'primary').on(:click) do |event|
            event.prevent_default
            reload
          end
          Toolbar::Button(text: I18n.t('crm.edit_query'), icon: 'filter', is_flex: true, target: "#edit_query_dialog", toggle: "modal", variant: 'primary')
          Toolbar::Button(text: I18n.t('crm.reset_filters'), icon: 'filter-circle-xmark', is_flex: true, variant: 'primary').on(:click) do |event|
            event.prevent_default
            reset_filters
          end
          Toolbar::Button(text: I18n.t('shared.configure'), icon: 'wrench', is_flex: true, target: "#edit-kanban-modal", toggle: "modal", variant: 'primary')
          toolbar_import_button
          toolbar_export_button(disabled: true)
          toolbar_delete_button(disabled: true)
        end
        Toolbar::Button(text: '', icon: 'search', is_flex: true, variant: 'primary').on(:click) do |event|
          event.prevent_default
          toggle_search_input
        end
      end
      global_search_input
    end

    def global_toolbar_bottom
      Portal(id: 'global-toolbar-bottom-menu') do
        Crm::BottomPanel(columns_render: 3) do
          bottom_panel_layout_selector_button
          BottomPanel::Button(target: '#edit_query_dialog', text: I18n.t('crm.edit_query'), icon: 'filter', toggle: "modal")
        end
        bottom_panel_layout_selector
      end
    end
  end
end
