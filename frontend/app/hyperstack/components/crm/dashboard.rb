# backtick_javascript: true

class Crm
  class Dashboard < Crm::Index::Base
    include Chart::Registry
    include Crm::Index::Exportable

    param :record_id
    param :width

    include WithMeasure
    with_measure ['width']

    before_unmount do
      deregister_all_charts
      @edit_all_procs = nil
      @merge_all_procs = nil
      @copy_all_procs = nil
      @export_all_procs = nil
      @delete_all_procs = nil
    end

    after_render do
      resize_all if width_changed?
    end

    def width_changed?
      width = ::Element["#grid-container"].width # TODO rewrite with_measure using a ResizeObserver
      result = @previous_width && width != @previous_width
      @previous_width = width
      return result
    end

    def selected_record_ids
      datatable_component.selected_rows_ids
    end

    def selected_chart
      return nil unless record && record.charts.any?
      selected = record.charts.detect { |c| c.id == @selected_chart_id }
      return selected if selected
      record.charts[0]
    end

    def selected_table_chart
      current_active_chart = selected_chart
      return current_active_chart if current_active_chart&.type == 'Table'
    end

    def datatable_component
      table_chart = selected_table_chart
      return unless table_chart
      ::Element.find("#table-#{table_chart.id}").data('get_component').call
    end

    def reload
      reload_data
    end

    render(DIV, class: 'crm-index') do
      global_toolbar
      next unless record&.loaded? && !record&.loading? && ready_for_init_search_query? && search_query
      @grid_charts = record.charts
      DIV(id: "grid-container", class: "mr-auto ml-auto", style: {width: (@edit_mode ? grid_width[@current_size] : '100%')})do
        DIV(style: {position: "relative"})do
          DIV(class: "grid-bg d-flex flex-wrap bg-white", style: {position: 'absolute', top: @margins/2, left: @margins/2, width: "calc(100% - #{@margins}px)"})do
            if grid_item_count > 0
              grid_item_count.times do
                DIV(style: {border: "1px solid #e5e5e5", width: "#{100/grid_cols[@current_size]}%", height: @row_height+@margins})
              end
            end
          end
        end if @edit_mode
        configure_btn if !@edit_mode && record.charts.empty?
        grid_layout(
          className: "layout",
          style: {position: "relative"},
          layouts: grid_layouts.to_n,
          isDraggable: @edit_mode,
          isRearrangeable: @edit_mode,
          isResizable: @edit_mode,
          rowHeight: @row_height,
          breakpoints: grid_breakpoints.to_n,
          cols: grid_cols.to_n,
          width: (@edit_mode ? grid_width[@current_size] : `undefined`),
          draggableHandle: "#drag-zone",
          onLayoutChange: change_temporary_data_proc,
        ) do
          @grid_charts.each do |chart|
            is_selected = selected_chart&.id == chart.id
            DIV(key: chart.id.to_n, class: "#{(@edit_mode ? "card" : "")} #{is_selected && !@edit_mode? 'chart-selected-primary' : ''}") do
              DIV(class: "position-absolute w-100 h-100", style: {zIndex: 300}) if @edit_mode #disables the chart on edit mode
              DIV(class:"card-header d-flex bg-light-yiq") do
                DIV(id: "drag-zone")
                Link(edit_chart_url(chart.id), class: "btn btn-light-yiq btn-xs", "data-open-panel": 'right') do
                  I(class: "fas fa-pencil-alt")
                end
                BUTTON(class: "btn btn-light-yiq btn-xs") do
                  I(class: "fa fa-times")
                end.on(:click) do |event|
                  event.prevent_default
                  Modal.confirm(title: I18n.t('shared.delete'), text: I18n.t('crm.dashboard_editor.delete_message', count: 1)) do
                    delete_chart(chart)
                  end
                end
              end if @edit_mode
              Chart.create_element(
                chart.attributes.merge(
                  uuid: chart.id,
                  registry: self,
                  record: chart,
                  groups: chart.groups,
                  draw_count: @draw_count,
                  class: (@edit_mode ? "card-body" : ""),
                  on_edit_all:   edit_all_proc(chart),
                  on_merge_all:  merge_all_proc(chart),
                  on_copy_all:   copy_all_proc(chart),
                  on_export_all: export_all_proc(chart),
                  on_delete_all: delete_all_proc(chart),
                )
              )
            end.on(:click) do
              unless @edit_mode
                @prevent_after_render_search = true
                @selected_chart_id = chart.id
                mutate
              end
            end.on(:mouse_enter)do |e|
              ::Element.find(e.current_target.to_n).find('.card-header').css('visibility', 'visible');
            end.on(:mouse_leave) do |e|
              ::Element.find(e.current_target.to_n).find('.card-header').css('visibility', 'hidden');
            end.on(:context_menu) do |e|
              unless e.ctrl_key || @edit_mode
                e.prevent_default
                show_dropdown(e, chart)
              end
            end
          end
        end
      end
      dropdown(native_state[:dropdown_param])
      edit_query_dialog
      export_all_modal
      edit_all_modal
      fullscreen_chart_modal
    end

    def fullscreen_chart
      return nil unless @fullscreen_chart_id
      record&.charts&.detect { |c| c.id == @fullscreen_chart_id }
    end

    def open_fullscreen_chart(chart_id)
      mutate @fullscreen_chart_id = chart_id
    end

    def close_fullscreen_chart
      mutate @fullscreen_chart_id = nil
    end

    def fullscreen_chart_modal
      chart = fullscreen_chart
      return unless chart

      DIV(class: 'dashboard-fullscreen-overlay bg-secondary', style: { position: 'fixed', inset: 0, zIndex: 20000, opacity: 0.5 }) do
      end.on(:click) do |e|
        e.prevent_default
        close_fullscreen_chart
      end

      DIV(key: "chart-fullscreen-#{chart.id.to_n}", class: 'dashboard-fullscreen-card bg-white d-flex flex-column m-3 rounded', style: { position: 'fixed', inset: 0, zIndex: 20001 }) do
        DIV(class: 'd-flex justify-content-end align-items-center p-2 border-bottom flex-shrink-0') do
          BUTTON(class: 'btn btn-sm btn-outline-secondary') do
            I(class: 'fas fa-times')
          end.on(:click) do |e|
            e.prevent_default
            close_fullscreen_chart
          end
        end

        DIV(id: "chart-fullscreen-#{chart.id}", class: 'w-100 flex-fill position-relative', style: { minHeight: 0 }) do
          Chart.create_element(
            chart.attributes.merge(
              uuid: "#{chart.id}-fullscreen",
              registry: self,
              record: chart,
              groups: chart.groups,
              draw_count: @draw_count,
              on_edit_all:   edit_all_proc(chart),
              on_merge_all:  merge_all_proc(chart),
              on_copy_all:   copy_all_proc(chart),
              on_export_all: export_all_proc(chart),
              on_delete_all: delete_all_proc(chart),
            )
          )
        end
      end.on(:context_menu) do |e|
        unless e.ctrl_key || @edit_mode
          e.prevent_default
          show_dropdown(e, chart)
        end
      end
    end

    def edit_all_modal
      return unless @params_for_edit_all
      Crm::EditAllModal(
        id: 'edit-all-modal',
        klass: klass,
        relation: selected_records_relation,
        **@params_for_edit_all
      ).on(:confirm) do
        reset_tables_selection
        reload
        @params_for_edit_all = nil
        mutate
      end.on(:close) do
        @params_for_edit_all = nil
        mutate
      end
    end

    def datatable_columns_to_export
      visible_and_filtered_columns(selected_table_chart)
    end

    def edit_all_proc(chart)
      @edit_all_procs ||= {}
      @edit_all_procs[chart.id] ||= Proc.new do |params, _all_selected, _selected_ids|
        @selected_chart_id = chart.id
        @params_for_edit_all = params
        mutate
      end
    end

    def merge_all_proc(chart)
      @merge_all_procs ||= {}
      @merge_all_procs[chart.id] ||= Proc.new do |_all_selected, _selected_ids|
        @selected_chart_id = chart.id
        merge_all_selected_records
      end
    end

    def copy_all_proc(chart)
      @copy_all_procs ||= {}
      @copy_all_procs[chart.id] ||= Proc.new do |_all_selected, _selected_ids|
        @selected_chart_id = chart.id
        copy_all_selected_records
      end
    end

    def export_all_proc(chart)
      @export_all_procs ||= {}
      @export_all_procs[chart.id] ||= Proc.new do |_all_selected, _selected_ids|
        @selected_chart_id = chart.id
        @export_all = true
        mutate
        after(0.1) do
          ::Element['#export-all-modal'].modal('show')
        end
      end
    end

    def delete_all_proc(chart)
      @delete_all_procs ||= {}
      @delete_all_procs[chart.id] ||= Proc.new do |_all_selected, _selected_ids|
        @selected_chart_id = chart.id
        ask_for_delete_selected_records
      end
    end

    def visible_and_filtered_columns(table_chart)
      result = []
      return result unless table_chart
      col_order = table_chart.columns || []
      names = ((col_order) + (search_query[:filters]&.keys || [])).uniq
      names&.each do |name|
        c = klass.datatable_column_by_name[name]
        result << c if c
      end
      return result
    end

    def all_selected?
      return false unless datatable_component
      datatable_component.all_selected?
    end

    def configure_btn
      DIV(class: 'd-flex align-items-center justify-content-center', style: {height: '90vh'}) do
        Link(edit_dashboard_url, class: 'btn btn-light-yiq') do
          I18n.t('shared.configure')
        end
      end
    end

    def change_temporary_data_proc
      return @change_temporary_data_proc ||= Proc.new do |layout, all_layout|
        @temporary_layout ||= grid_layouts
        updated = layout.map{|o| Hash.new(o).select { |k, v| !v.nil? }}
        if @current_size && updated != @temporary_layout[@current_size]
          @temporary_layout[@current_size] = updated
          mutate
        end
      end
    end

    def global_search_input
      unless @edit_mode
        super
      end
    end

    before_mount do
      @margins = 10
      @row_height = 130
      @edit_mode = false
      @temporary_layout = nil
      @selected_chart_id = nil
      @fullscreen_chart_id = nil
    end

    def init
      @edit_mode = request.params[:action] == 'edit'

      if query_path_changed? || action_changed? || edit_mode_changed?
        @record_klass = nil
        @previous_klass = klass
        @previous_record_updated_at = nil

        @draw_count ||= 0
        @draw_count += 1
      end

      super

      if location_query_changed?
        @previous_location_query = request.params[:_]
        charts.values.each do |c|
          c.set_filter_from_dashboard
          c.set_sort_from_dashboard
          c.set_contains_from_dashboard
        end
      end

      if edit_mode_changed?
        @temporary_layout = nil
        if @edit_mode
          @current_size = compute_current_size
        end
      end
    end

    def edit_mode_changed?
      @edit_mode != @previous_edit_mode
    end

    def compute_current_size
      screen_width = `window.innerWidth`
      grid_breakpoints.each do |k, v|
        return k if screen_width > v
      end
      return :xs
    end

    def grid_layout(*args)
      if @edit_mode
        ReactGridLayout::Responsive(*args) do
          yield if block_given?
        end
      else
        self::WidthProvider(*args) do
          yield if block_given?
        end
      end
    end

    def global_toolbar_left
      if @edit_mode
        Portal(id: 'global-toolbar-left') do
          Link(last_search_url, class: "btn btn-transparent-primary mx-2") do
            I(class: 'pr-2 fa fa-chevron-left fa-fw')
            SPAN do
              I18n.t("shared.back")
            end
          end.on(:click) do |event|
            event.prevent_default
            if layout_saved?
              close_edit_mode
            else
              Modal.confirm(title: I18n.t('shared.back'), text: I18n.t('crm.dashboard_editor.close_without_saving')) do
                close_edit_mode
              end
            end
          end
        end
      else
        super
      end
    end

    def global_toolbar_center
      Portal(id: 'global-toolbar-center') do
        if @edit_mode
          SELECT(class: "custom-select bg-light-yiq w-auto border-0", style: {cursor: 'pointer'}, value: @current_size) do
            [:lg, :md, :sm, :xs].each do |screen_size|
              OPTION(value: screen_size) do
                I18n.t("crm.dashboard_editor.screen_size.#{screen_size}")
              end
            end
          end.on(:change) {|e| mutate @current_size = e.target.value }
        end
      end
    end

    def global_toolbar_right
      Portal(id: 'global-toolbar-right') do
        unless @edit_mode
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
            Toolbar::Button(text: I18n.t('shared.configure'), icon: 'wrench', is_flex: true, target: edit_dashboard_url, variant: 'primary')
            toolbar_import_button
            toolbar_export_button(disabled: !selected_table_chart.present?)
            toolbar_doc_gen_button(disabled: !selected_table_chart.present?) do |event|
              event.prevent_default
              records = datatable_component.rows(selected: true).data.to_a.map{|r| klass.new(r.to_h)}
              ::Element.find('#docgen-modal').trigger('show.dynamo.modal', [{ records: records }])
            end
            toolbar_delete_button(disabled: !selected_table_chart.present?)
          end

          Toolbar::Button(text: '', icon: 'search', is_flex: true, variant: 'primary').on(:click) do |event|
            event.prevent_default
            toggle_search_input
          end
        else
          Link(new_chart_url, class: "btn btn-transparent-primary mx-2", 'data-open-panel': 'right') do
            I18n.t("shared.new")
          end
          BUTTON(class: "btn btn-primary mx-2") do # TODO improve feedback
            I18n.t("shared.save")
          end.on(:click) do
            self.save_layouts&.then do |success|
              if success
                @temporary_layout = nil
              else
                # TODO
              end
            end
          end
        end
      end
      global_search_input
    end

    def global_toolbar_bottom
      Portal(id: 'global-toolbar-bottom-menu') do
        Crm::BottomPanel(columns_render: 3) do
          bottom_panel_layout_selector_button
          BottomPanel::Button(target: '#edit_query_dialog', text: I18n.t('crm.edit_query'), icon: 'pen', toggle: "modal")
        end
        bottom_panel_layout_selector
      end
    end

    def edit_dashboard_url(query_dump: request.params[:_])
      r = "#{index_url(klass)}/edit"
      r = add_param_to_url(r, :_, query_dump.gsub('+', '%2B')) if query_dump.present?
      r = add_param_to_url(r, :l, request.params[:l]) if request.params[:l].present?
      r = add_param_to_url(r, :mi, request.params[:mi]) if request.params[:mi].present?
      return r
    end

    def new_chart_url
      "/crm/#{request.params[:schema]}/dashboards/#{record_id}/charts/new?klass_name=#{new_chart_klass_name}"
    end

    def new_chart_klass_name
      schema.klasses&.detect{|k| k.route_key == request.params[:klass]}&.const_absolute_name
    end

    def close_edit_mode
      App.history.push(search_url(klass, search_query))
    end

    def layout_saved?
      return @temporary_layout.nil?
    end

    def dropdown(chart_id)
      return if chart_id.nil?
      if @fullscreen_chart_id == chart_id
        chart_obj = charts["#{chart_id}-fullscreen"] || charts[chart_id]
      else
        chart_obj = charts[chart_id]
      end
      DIV(class: 'chart-contextmenu dropdown-menu') do
        if false # TODO fix maximize
          Link("/crm/#{request.params[:schema]}/chart/#{request.params[:klass]}/last_search?id=#{chart_id}", class: 'dropdown-item') do
            I(class: 'fas fa-expand fa-fw pr-3')
            I18n.t("crm.dashboard.maximize_chart")
          end
        end
        BUTTON(class: 'btn btn-link dropdown-item') do
          Link(edit_chart_url(chart_id), class: 'hidden_link d-none', "data-open-panel": 'right') {}
          I(class: 'fas fa-pencil-alt fa-fw pr-3')
          I18n.t("crm.dashboard.edit_chart")
        end.on(:click) do |event|
          event.prevent_default
          ::Element[event.current_target.to_n].find('.hidden_link').click()
        end
        unless chart_obj.is_a?(::Crm::Chart::Table)
          chart_obj.context_buttons
        end
      end
    end

    def edit_chart_url(chart_id)
      "/crm/#{request.params[:schema]}/dashboards/#{record.id}/charts/#{chart_id}/edit"
    end

    def show_dropdown(event, chart)
      x = event.page_x
      y = event.page_y
      self.set_state({dropdown_param: chart.id}) do
        menu = ::Element.find('.chart-contextmenu')
        menu.css(top: y, left: x, 'z-index': 100000).show()
        ::Element.find('body').on(:click) do |event|
          `setTimeout(#{
            Proc.new do
              menu.hide()
              self.set_state({dropdown_param: nil})
            end
           },100)`
        end
      end
    end

    def grid_cols
      { lg: 12, md: 10, sm: 6, xs: 4 }
    end

    def grid_breakpoints # eg. {lg: 1200, md: 992, sm: 768, xs: 0}
      return @grid_breakpoints if @grid_breakpoints
      @grid_breakpoints = {}
      TO_BOOTSTRAP.each do |grid_size, bs_size|
        @grid_breakpoints[grid_size] = grid_size == :xs ? 0 : bootstrap_breakpoints[bs_size] - 1
      end
      return @grid_breakpoints
    end

    def grid_width # eg. {lg: 1201, md: 993, sm: 769, xs: 574}
      return @grid_width if @grid_width
      @grid_width = {}
      TO_BOOTSTRAP.each do |grid_size, bs_size|
        @grid_width[grid_size] = bootstrap_breakpoints[bs_size]
      end
      return @grid_width
    end

    def bootstrap_breakpoints # eg. {xl: 1200, lg: 992, md: 768, sm: 576, xs: 0}
      return @bootstrap_breakpoints if @bootstrap_breakpoints
      @bootstrap_breakpoints = {}
      `var style = window.getComputedStyle(document.documentElement)`
      [:xl, :lg, :md, :sm, :xs].each do |size|
        @bootstrap_breakpoints[size] = `style.getPropertyValue('--breakpoint-' + size)`.gsub('px', '').strip.to_i
      end
      return @bootstrap_breakpoints
    end

    TO_BOOTSTRAP = {
      :lg => :xl,
      :md => :lg,
      :sm => :md,
      :xs => :sm,
    }

    def grid_items_height(size)
      grid_layouts[size].map{ |e| e[:h] + e[:y]}.max || 0
    end

    def grid_item_count
      return 0 unless record.charts.any?
      grid_items_height(@current_size) * grid_cols[@current_size]
    end

    def grid_layouts
      return temporary_layout unless @temporary_layout.nil?
      layouts = {}
      @grid_charts.each do |c|
        grid_breakpoints.keys.each do |size|
          layouts[size] ||= []
          layouts[size].push((c.layouts[size] || {x: 0, y: layouts[size].map{ |e| e[:h] + e[:y]}.max || 0, w: 2, h: 2}).merge({i: c.id}))
        end
      end
      return layouts
    end

    def temporary_layout
      return if @temporary_layout.nil?
      @grid_charts.each do |c|
        @temporary_layout.keys.each do |size|
          if (@temporary_layout[size].detect { |l| l[:i] == c.id }).nil?
            #default position for charts that aren't in the temporary_layout yet
            @temporary_layout[size].push({x: 0, y: @temporary_layout[size].map{ |e| e[:h] + e[:y]}.max || 0, w: 2, h: 2}.merge({i: c.id}))
          end
        end
      end
      return @temporary_layout
    end

    def set_charts_layouts(new_layouts)
      new_layouts.each do |layout|
        chart = @grid_charts.detect {|c| c.id == layout.JS[:i]}
        chart.layouts[@current_size] = Hash.new(layout).except(:i).select { |k, v| !v.nil? }
      end
      @temporary_layout = nil
      @temporary_layout = grid_layouts
    end

    def record
      return unless record_klass && record_id.present?
      return observe record_klass.with_includes_for_load.find(record_id)
    end

    def dashboard_id
      record_id
    end

    def record_klass
      @record_klass ||= "#{klass.parent.name}::R::Dashboard".safe_constantize
    end

    def chart_records
      return [] unless record && record.loaded? && record.charts&.any?
      return record.charts
    end

    def delete_chart(chart_to_delete)
      chart_to_delete.destroy.then do |response|
        if response[:success]
          search_query.delete_chart(::Crm::Chart::Base.url_id(chart_to_delete.id))
          self.deregister(chart_to_delete.id)
          update_query_record
          App.history.replace(edit_dashboard_url(query_dump: search_query.dump))
        end
      end
    end

    def save_layouts
      return unless @temporary_layout
      return record.update(
        charts_attributes: @grid_charts.map do |c|
          {id: c.id, type: c.type, layouts: layouts_for_chart(c.id)}
        end
      )
    end

    def layouts_for_chart(chart_id)
      r = {}
      @temporary_layout.each do |size, layouts|
        l = layouts.detect{|l| l[:i] == chart_id}
        r[size] = l.except(:i, :moved, :static) if l
      end
      return r
    end

    after_update do
      if edit_mode_changed?
        @previous_edit_mode = @edit_mode
      end
    end

    def ready_for_init_search_query?
      (observe klass.options_for_indexed_json).loaded?
    end

    def search_query_defaults
      table = record.charts.detect{|c| c.type == 'Table' }
      return unless table
      return {table: {columns: table.columns || default_columns_from_elasticsearch}}
    end

    def default_columns_from_elasticsearch
      o = klass.options_for_indexed_json.try(:[], :only)
      return [] unless o
      return o.select{|attr| !attr.end_with?('_id')} - ['created_at', 'updated_at', 'deleted_at']
    end

    def self.to_n
      Hyperstack::Internal::Component::ReactWrapper.create_native_react_class(self)
    end

    class WidthProvider < HyperComponent
      #Wrapps the class with WidthProvider
      imports `ReactGridLayout.WidthProvider(ReactGridLayout.Responsive)`
    end

  end
end
