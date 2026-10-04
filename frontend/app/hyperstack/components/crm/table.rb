require 'components/crm/query/dialog'
require 'components/crm/workflow/trigger_action'

class Crm
  class Table < Crm::Index::Base
    include Crm::Index::Exportable
    include Crm::Workflow::TriggerAction

    render(DIV, class: 'crm-index') do
      global_toolbar
      if search_query && request.params[:action] != 'last_search'
        redraw_datatable if search_query_params_changed?
        Crm::Datatable(
          id: "crm_table",
          klass: klass,
          search_query: search_query,
          draw: @draw,
          dt_classes: {dataTables_scroll: "border-0"}
        ).on(:launch_search) do
          search
        end.on(:open_column_param_modal) do |klass, attr|
          @attr = attr
          @show_column_param_modal = true
          mutate
        end.on(:columns_reordered) do |columns|
          search_query[:table][:columns] = columns
          update_query_record
          App.history.replace(search_url(klass, search_query))
        end.on(:order_changed) do |s|
          search_query[:table][:order] = s
          update_query_record
          App.history.replace(search_url(klass, search_query))
        end.on(:column_locked) do |c|
          if c
            search_query[:table][:locked] = c
          else
            search_query[:table].delete(:locked)
          end
          update_query_record
          App.history.replace(search_url(klass, search_query))
        end.on(:column_locked_right) do |c|
          if c
            search_query[:table][:locked_right] = c
          else
            search_query[:table].delete(:locked_right)
          end
          update_query_record
          App.history.replace(search_url(klass, search_query))
        end.on(:columns_resized) do |column_widths|
          search_query[:table][:width] = column_widths
          update_query_record
          App.history.replace(search_url(klass, search_query))
        end.on(:edit_all) do |params|
          @params_for_edit_all = params
          mutate
        end.on(:merge_all) do
          merge_all_selected_records
        end.on(:copy_all) do
          copy_all_selected_records
        end.on(:export_all) do |params|
          @export_all = true
          mutate
        end.on(:delete_all) do
          ask_for_delete_selected_records
        end.on(:action_click) do |data|
          execute_trigger_action(data)
        end.on(:summary_changed) do |col_name, new_op, default_op|
          search_query[:table] ||= {}
          if new_op == default_op
            search_query[:table][:summary]&.delete(col_name)
            search_query[:table].delete(:summary) if search_query[:table][:summary]&.empty?
          else
            search_query[:table][:summary] ||= {}
            search_query[:table][:summary][col_name] = { 'ops' => [new_op] }
          end
          search
        end
      end

      Crm::Table::Column::Modal(id: 'column_modal', klass: klass, search_query: search_query.try(:[], :table), reload: reload?).on(:columns_selection) do
        search
      end

      export_all_modal
      if @params_for_edit_all
        Crm::EditAllModal(id: 'edit-all-modal', relation: selected_records_relation, **@params_for_edit_all).on(:confirm) do
          reload
        end.on(:close) do
          @params_for_edit_all = nil
        end
      end

      edit_query_dialog

      # Bottom action toolbar for mobile
      footer
    end # end render

    def datatable_columns_to_export
      visible_and_filtered_columns
    end

    def visible_and_filtered_columns
      result = []
      @col_order = search_query[:table][:columns] || []
      names = ((@col_order) + (search_query[:filters]&.keys || [])).uniq
      names&.each do |name|
        c = klass.datatable_column_by_name[name]
        result << c if c
      end
      return result
    end

    def global_toolbar_right
      Portal(id: 'global-toolbar-right') do
        GroupDrop(maxnum: 3, variant: 'primary') do
          has_search_query_columns = search_query && search_query.dig(:table, :columns).try(:any?)

          Toolbar::Button(target: new_url(klass), text: I18n.t('shared.new'), icon: 'plus', is_flex: true, "data-open-panel": 'right', variant: 'primary')
          #Toolbar::Button(text: I18n.t('shared.select'), icon: 'check-square', is_flex: true) # TODO: show only on mobile
          if has_search_query_columns
            Toolbar::Button(text: I18n.t('shared.refresh'), icon: 'redo', is_flex: true, variant: 'primary').on(:click) do |event|
              event.prevent_default
              reload
            end
          end
          Toolbar::Button(text: I18n.t('crm.choose_columns'), icon: 'window-maximize', is_flex: true, target: "#column_modal", toggle: "modal", variant: 'primary')
          Toolbar::Button(text: I18n.t('crm.edit_query'), icon: 'filter', is_flex: true, target: "#edit_query_dialog", toggle: "modal", variant: 'primary')
          Toolbar::Button(text: I18n.t('crm.reset_filters'), icon: 'filter-circle-xmark', is_flex: true, variant: 'primary').on(:click) do |event|
            event.prevent_default
            reset_filters
          end
          Toolbar::Button(text: I18n.t('crm.reset_order'), icon: 'arrow-down-up-across-line', is_flex: true, variant: 'primary').on(:click) do |event|
            event.prevent_default
            reset_order
          end
          toolbar_import_button
          if has_search_query_columns
            toolbar_export_button
            toolbar_doc_gen_button do |event|
              event.prevent_default
              records = datatable_component.rows(selected: true).data.to_a.map{|r| klass.new(r.to_h)}
              ::Element.find('#docgen-modal').trigger('show.dynamo.modal', [{ records: records }])
            end
          end
          toolbar_delete_button if has_search_query_columns
        end
        Toolbar::Button(text: '', icon: 'search', is_flex: true, variant: 'primary').on(:click) do |event|
          event.prevent_default
          toggle_search_input
        end
      end
      global_search_input
    end

    def toggle_search_input
      search_input = ::Element['.search-input-field']
      search_input.toggle_class('d-none')
      search_input_height = search_input.outer_height(true)
      if search_input.has_class?('d-none')
        search_input.remove_class('d-none')
        search_input_height = search_input.outer_height(true)
        search_input.add_class('d-none')
      end

      data_tables = ::Element['.dataTables_scrollBody']
      current_height = data_tables.css('height').to_f
      new_height = search_input.visible? ? (current_height - search_input_height) : (current_height + search_input_height)
      data_tables.css('height', "#{new_height}px")
    end

    def global_toolbar_bottom
      Portal(id: 'global-toolbar-bottom-menu') do
        Crm::BottomPanel(columns_render: 3) do
          BottomPanel::Button(target: '#column_modal', text: I18n.t('crm.choose_columns'), icon: 'window-maximize', toggle: "modal")
          BottomPanel::Button(target: '#edit_query_dialog', text: I18n.t('crm.edit_query'), icon: 'filter', toggle: "modal")
          bottom_panel_delete_button
          bottom_panel_layout_selector_button
        end
        bottom_panel_layout_selector
      end
    end

    before_new_params do |next_props|
      @columns_changed = (next_props[:search_query] && next_props[:search_query].try(:dig, :table, :columns) != @search_query.try(:dig, :table, :columns))
    end

    def reset_search_query?
      super || @columns_changed
    end

    def highlight(line)
      return if line&.tag_name != 'tr'
      unhighlight
      line.addClass('highlight-table-line')
    end

    def unhighlight
      ::Element.find(".highlight-table-line").removeClass('highlight-table-line')
    end

    def search
      redraw_datatable
      super
    end

    def reload
      redraw_datatable
      super
    end

    def redraw_datatable
      @draw ||= 0
      @draw += 1
    end

    def ready_for_init_search_query?
      (observe klass.options_for_indexed_json).loaded?
    end

    def search_query_defaults
      {table: {columns: default_columns}}
    end

    def default_columns
      o = klass.options_for_indexed_json.try(:[], :only)
      return unless o
      return o.select{|attr| !attr.end_with?('_id')} - ['created_at', 'updated_at', 'deleted_at']
    end

    def all_selected?
      datatable_component.all_selected?
    end

    def selected_record_ids
      datatable_component.selected_rows_ids
    end

    def datatable_component
      ::Element.find('#crm_table').data('get_component').call
    end

  end

end
