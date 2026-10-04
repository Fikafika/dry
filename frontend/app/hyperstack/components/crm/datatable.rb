# backtick_javascript: true
require 'components/crm/workflow/trigger_cache'

class Crm::Datatable < ::Datatable
  include Hyperstack::Router::Helpers
  include Crm::Datatable::RecordFromCell
  include Crm::Datatable::SummaryRenderer
  include Protocol::DropdownItem

  param :klass
  param :id
  param :search_query
  param :search_query_key, default: :table
  param :dt_classes, default: nil
  param :default_columns, default: nil
  param :allow_select_all_rows, default: true

  collect_other_params_as :other_params

  fires :launch_search
  fires :open_filter_modal
  fires :open_column_param_modal
  fires :edit_cell
  fires :edit_all
  fires :merge_all
  fires :copy_all
  fires :delete_all
  fires :export_all
  fires :columns_reordered
  fires :columns_resized
  fires :column_locked
  fires :column_locked_right
  fires :order_changed
  fires :column_deleted
  fires :action_click
  fires :summary_changed
  fires :init

  alias_native :query

  attr_accessor :draw_callbacks

  include Crm::Workflow::TriggerCache

  render() do
    next unless klass_loaded?
    if search_query_columns&.any?
      TABLE(id: id, class: "table table-sm table-bordered nowrap #{other_params[:className]}") do
        THEAD() do
          TR() do
            TH(key: 'C_0', class: 'border-top-0') do
              if allow_select_all_rows
                SelectAllRowsHeader(key: 'CH_0', datatable: self) do
                end.on(:change) do |selected|
                  @all_selected = selected
                  @selected_rows.clear
                end
              end
            end
            visible_columns.each do |col|
              TH(key: col.name, class: "border-top-0 data-column", "data-attr": col.name) do
                ColumnHeader(key: "CH_#{col.name}", klass: klass, column: col, sort_index: sort_index_for_column(col.name)) do
                end.on(:click_delete) do |column|
                  if search_query_columns.length > 1
                    search_query_columns.delete(column.name)
                  end
                  @col_order = nil
                  column_deleted!(column.name)
                  launch_search!
                end.on(:column_param) do
                  open_column_param_modal!(col.klass, col.method_name)
                end.on(:reorder) do |data|
                  handle_column_reorder(data[:column], data[:direction], data[:multi])
                end.on(:show_lock_menu) do |data|
                  @lock_menu_position = {x: data[:x], y: data[:y]}
                  @lock_menu_column = data[:column]
                  mutate
                end
                FilterInput(key: "FI_#{col.name}", search_query: search_query, name: col.name, column: col, reload: timestamp).on(:launch_search) do
                  reset_selection
                  launch_search!
                end.on(:click_icon_filter) do
                  @value = ::Element.find(".filter-#{col.css_class}").children.find("input").value
                  @show_filter_modal = true
                  @attr = col.name
                  mutate
                  open_filter_modal!(col.klass, @attr, @value)
                end
              end
            end
          end
        end
        TFOOT(class: 'datatable-summary') do
          TR() do
            TH(key: 'SF_0', class: 'summary-footer-cell') {}
            visible_columns.each do |col|
              TH(key: "SF_#{col.name}", class: 'summary-footer-cell', "data-summary-col": col.name) {}
            end
          end
        end
      end.on(:context_menu) do |event|
        next if event.ctrl_key
        event.prevent_default
        event.stop_propagation
        show_context_menu(event)
      end
    else
      DIV(class: 'p-2') do
        DIV(class: 'alert alert-warning') do
          ::I18n.t('crm.datatable.missing_columns', klass_name: klass.model_name.human.capitalize)
        end
      end
    end

    Portal(id: 'datatable-portal', parentSelector: '.router-top-level') do
      Crm::Filters::Modal(search_query: search_query, attr: @attr, value: @value, klass: klass, show: @show_filter_modal).on(:launch_search) do
        @show_filter_modal = false
        mutate
        launch_search!
      end.on(:cancel) do
        @show_filter_modal = false
        mutate
      end
      if @cell
        Crm::Datatable::CellEditor(klass: klass, cell: @cell).on(:close) do
          @cell = nil
          mutate
        end
      end

      context_menu
      lock_menu
    end
  end

  before_mount do
    remove_datatable
    set_datatable_err_mode
  end

  before_unmount do
    remove_datatable
  end

  after_mount do
    init_datatable
  end

  after_new_params do
    if search_query_columns_changed? || default_columns_changed?
      # we remove datatable because it crashes in react when a column header has been removed by datatable
      remove_datatable
    end
  end

  after_update do
    if @table
      if search_query_locked_changed?
        update_locked_column
      end
      if search_query_locked_right_changed?
        update_locked_right_column
      end
      if search_query_order_changed?
        update_order
      end
    end

    init_datatable

    if other_params_draw_changed? || search_query_changed?
      reset_selection
      draw
    end

    adjust_height
  end

  def search_query_columns
    other_params[:columns] || search_query.dig(search_query_key, :columns)
  end

  def search_query_locked
    return other_params[:locked_column] if other_params.has_key?(:locked_column)
    search_query.dig(search_query_key, :locked)
  end

  def search_query_locked_right
    return other_params[:locked_column_right] if other_params.has_key?(:locked_column_right)
    search_query.dig(search_query_key, :locked_right)
  end

  def search_query_filters
    search_query.dig(:filters)
  end

  def search_query_order
    other_params[:order] || search_query.dig(search_query_key, :order)
  end

  def search_query_width
    other_params[:column_widths] || search_query.dig(search_query_key, :width)
  end

  track_changes :search_query_columns, :search_query_locked, :search_query_locked_right, :search_query_order, [:other_params, :draw], :default_columns, :search_query_filters, :search_query_width

  def search_query_changed?
    search_query_columns_changed? || search_query_locked_changed? || search_query_locked_right_changed? || search_query_order_changed? || search_query_filters_changed? || search_query_width_changed?
  end

  def update_locked_column
    anchor_idx = visible_columns.index { |c| c.name == search_query_locked }
    last_left = anchor_idx && anchor_idx > 0 ? visible_columns[anchor_idx - 1] : nil
    lock_column(last_left)
  end

  def lock_column(col)
    if col
      col_index = column(%Q[[data-attr="#{col.name}"]]).index
      fixedColumns.left = col_index + 1
      return col.name
    else
      fixedColumns.left = 0
    end
  end

  def update_locked_right_column
    anchor_idx = visible_columns.index { |c| c.name == search_query_locked_right }
    first_right = anchor_idx && anchor_idx + 1 < visible_columns.length ? visible_columns[anchor_idx + 1] : nil
    lock_right_column(first_right)
  end

  def lock_right_column(col)
    if col
      col_index = column(%Q[[data-attr="#{col.name}"]]).index
      total_visible = columns().visible().count
      fixedColumns.right = total_visible - col_index
      return col.name
    else
      fixedColumns.right = 0
    end
  end

  def update_order
    @current_order = nil
    current = normalized_order
    if current.any?
      apply_multi_order(current)
    else
      order([])
    end
  end

  def init_datatable(redraw = false)
    return if @table || !klass_loaded?
    @draw_callbacks = []

    settings = default_table_settings

    if request.params[:action] == 'search'
      add_search_to_settings(settings)
    end

    t = ::Element.find("##{id}")

    @native = @table = t.DataTable(
      settings
    )

    add_dt_classes # add before init.dt because init.dt is called only afte ajax completed (prevent a blink effect)
    `#{t}.on("init.dt", #{Proc.new do
        remove_order_listeners
      end
    })`

    self.jq_node.data('table', Proc.new{ @table })
    self.jq_node.data('get_component', Proc.new{ self })

    workaround_remove_child

    init_cell_edit
    init_cell_hover

    native_off('column-reorder.dt.mouseup')
    native_on('column-reorder.dt.mouseup') do |e, settings, details|
      if e.JS[:namespace] == "dt.mouseup"
        columns_reorder
      end
    end
    native_off('column-resize.dt.mouseup')
    native_on('column-resize.dt.mouseup') do |e, settings, details|
      columns_resize
    end

    draw if redraw

    init_select_rows
    init_action_click
    init_trigger_cache

    init!(@native)
    init_summary
  end

  def klass_loaded?
    return false unless klass
    observe klass.options_for_indexed_json
    return klass.options_for_indexed_json.any?
  end

  def columns_reorder
    vis_col = columns().visible().to_a
    vis_indexes = []
    vis_col.each_with_index do |val, i|
      if val
        vis_indexes.push(i)
      end
    end
    order = []
    vis_indexes.each do |idx|
      unless idx == 0
        order.push(column(idx).name())
      end
    end
    return if order == @col_order
    remove_order_listeners
    columns_reordered!(order)
    @col_order = order
  end

  def columns_resize
    data_columns = ::Element["##{id} th.data-column"]
    column_widths = {}
    data_columns.each do |column|
      column_widths[column.attr("data-attr")] = column.width()
    end
    columns_resized!(column_widths)
  end

  def add_search_to_settings(settings)
    if search_query[:q].present?
      settings[:search] = {search: search_query[:q]} # Initialize the table with a global search (:q) is pretty straightforward...
    end
    if search_query_filters.present?
      # ...doing the same thing for column search is a pain beacause we have to pass an hash for each column we want to search but we don't have @table yet !
      # We need to play with the columns list we have in settings and the filters hash
      filters_hash = {}
      filters_keys = []
      search_query_filters.each do |k, v|
        filters_hash[k] = v
        filters_keys << k
      end
      col_to_search = Array.new(settings[:columns].length)
      filters_keys.each do |k|
        settings[:columns].each do |h|
          if h["name"] == k
            col_to_search[h["target"]] = {"search": filters_hash[k]}
          end
        end
      end
      settings[:searchCols] = col_to_search
    end
    current = normalized_order
    if current.any?
      dt_order = current.filter_map do |pair|
        col_name, dir = pair
        col = settings[:columns].detect { |h| h["name"] == col_name }
        [col['target'], dir] if col
      end
      settings[:order] = dt_order if dt_order.any?
    end
  end

  def normalized_order
    @current_order || normalize_order(search_query_order)
  end

  def normalize_order(order)
    return [] if order.nil? || order.empty?
    order[0].is_a?(String) ? [order] : order
  end

  def apply_multi_order(order_array)
    dt_order = order_array.map do |pair|
      col_name, dir = pair
      col_index = column(%Q[[data-attr="#{col_name}"]]).index
      [col_index, dir]
    end
    order(dt_order.to_n)
  end

  def sort_index_for_column(col_name)
    current = normalized_order
    idx = current.index { |pair| pair[0] == col_name }
    idx && current.length > 1 ? idx + 1 : nil
  end

  def handle_column_reorder(column, direction, multi = false)
    current = (@current_order || normalized_order).dup
    if multi
      existing_index = current.index { |pair| pair[0] == column.name }
      if existing_index
        if current[existing_index][1] == direction
          current.delete_at(existing_index)
        else
          current[existing_index] = [column.name, direction]
        end
      else
        current << [column.name, direction]
      end
    else
      existing = current.detect { |pair| pair[0] == column.name }
      if existing && current.length == 1
        if existing[1] == direction
          current = []
        else
          current = [[column.name, direction]]
        end
      else
        current = [[column.name, direction]]
      end
    end
    @current_order = current
    if current.any?
      apply_multi_order(current)
    else
      order([])
    end
    order_changed!(current)
    draw
  end

  def default_table_settings
    @klass_name = klass.name.demodulize.downcase

    col_defs = columns_default || []

    if klass.parent.feature_enabled?('Dynamic::Datatable::Style::Feature')
      col_defs.concat(styled_column_defs)
    end

    result = {
      data: [],
      ajax: ajax,
      colReorder: {
        fixedColumnsLeft: 1,
        fixedColumnsRight: locked_right_index,
        realtime: false,
      },
      columnDefs: col_defs,
      columns: column_settings,
      defRender: true,
      dom: "R"+
           "<'row no-gutters'<'col-sm-12'tr>>" +
           "<'row no-gutters'<'col-sm-12 col-md-5'i><'col-sm-12 col-md-7'p>>",
      fixedColumns: {  # fixedColumns in colReorder replace this ?
        leftColumns: locked_index,
        rightColumns: locked_right_index
      },
      info: false,
      language: I18n.t('datatable'),
      order: [], #if empty, order is given by server
      orderCellsTop: true, # ordering is on top cells (for multiple header)
      paging: true, # this must be true for scroller
      processing: false,
      #retrieve: true, # equivalent of: if .isDataTable => .DataTable, else => .DataTable
      scrollCollapse: false,
      scrollX: true, # default false
      scrollY: scrollY, # scrollY is mandatory for scroller
      select: {    # TODO: implement getter for selected items: https://datatables.net/extensions/select/examples/api/get.html
        style:    'multi',
        selector: 'td:first-child' # allow selection on the first column only (i.e. the checkbox)
      },
      serverSide: true,
      autoWidth: false,
      rowId: 'id', # needed for identify a row
      rowCallback: Proc.new do |row, data|
        id = `#{row}.id`
        if @all_selected
          unless @selected_rows.include?(id)
            `$(#{row}).addClass('selected')`
          end
        else
          if @selected_rows.include?(id)
            `$(#{row}).addClass('selected')`
          end
        end
      end,
      drawCallback: Proc.new do |settings|
        ::Element['.dataTables_wrapper [data-toggle="tooltip"]'].tooltip({html: true, sanitize: false}.to_n)
        if draw_callbacks.any?
          draw_callbacks.each{|c| c.call }
          draw_callbacks = []
        end
        calculate_height
      end,
      footerCallback: Proc.new do |tfoot, data, start, end_pos, display|
        json_data = `#{@table}.ajax.json()`
        if json_data
          summaries = Native(json_data)[:summaries]
          render_footer_cells(tfoot, summaries) if summaries
        end
      end,
    }

    infinite_scroll = false
    if infinite_scroll
      result.merge!(
        scroller: {
          loadingIndicator: true,
          displayBuffer: 2, # number of pages preloaded at each ajax call
        },
        dom: "R" +
          "<'row no-gutters'<'col-sm-12'tr>>" +
          "<'row no-gutters'<'col-sm-12 col-md-5'i><'col-sm-12 col-md-7'p>>",
      )
    else
      per_page = 200
      footer_height = 89 # paginate + summary
      result.merge!(
        pagingType: 'full_numbers',
        pageLength: per_page,
        lengthChange: false,
        dom: "R" +
          "<'row no-gutters'<'col-sm-12'tr>>"   +
          "<'row no-gutters dataTables_footer'<'col-sm-12 col-md-5'i><'col-sm-12 col-md-7 pr-3 pt-1'p>>",
        scrollY: "calc(#{scrollY} - #{footer_height}px)", # scrollY is mandatory for scroller
      )
    end

    if klass.parent.feature_enabled?('Dynamic::Datatable::Style::Feature')
      add_styled_row_callback(result)
    end

    return result
  end

  def add_styled_row_callback(settings)
    style_callback = styled_row_callback
    return unless style_callback

    existing_created_row = settings[:createdRow]
    if existing_created_row
      settings[:createdRow] = lambda do |row, data, data_index|
        existing_created_row.call(row, data, data_index)
        style_callback.call(row, data, data_index)
      end
    else
      settings[:createdRow] = style_callback
    end
  end

  def ajax
    return other_params[:ajax] if other_params[:ajax]
    return {
      url: "#{klass.api_path}/datatable",
      type: "POST",
      data: Proc.new do |d|
        `#{d}.time_zone = Intl.DateTimeFormat().resolvedOptions().timeZone`
        `#{d}.search_query = #{search_query.dump}`
        d
      end
    }
  end

  def remove_datatable
    return unless @table
    cleanup_summary
    clear().destroy()
    @native = @table = nil
    @col_order = nil
    @current_order = nil
    reset_trigger_cache
  end

  def calculate_height
    return if other_params[:height].nil?
    after(0.1) do
      if ::Element.find("##{id}_wrapper").length > 0
        wrapper = ::Element.find("##{id}_wrapper")
        scroll_head = wrapper.find(".dataTables_scrollHead")
        scroll_body = wrapper.find(".dataTables_scrollBody")
        scroll_foot = wrapper.find(".dataTables_scrollFoot")
        scroll_parent = scroll_body.closest('.dataTables_scroll')
        footer = wrapper.find(".dataTables_footer")
        footer_height = footer.outer_height(true)
        footer_height = 50 if footer_height.nil? || footer_height <= 0
        scroll_foot_height = scroll_foot.outer_height(true) || 0
        h = other_params[:height] - scroll_head.height() - (scroll_parent.outer_height(true) - scroll_parent.height()) - footer_height - scroll_foot_height
        scroll_body.css('height', "#{h}px")
        scroll_body.css('max-height', "")
      end
    end
  end

  def adjust_height
    Document.ready? do
      if !other_params[:height].nil? && other_params[:height] != @previous_height
        @previous_height = other_params[:height]
        calculate_height
      end
    end
  end

  def scrollY
    return other_params[:scroll_y] if other_params[:scroll_y]
    unless other_params[:height].nil? || other_params[:height] <= 0
      Document.ready? do
        @previous_height = other_params[:height]
        scroll_head_height = ::Element.find("##{id}_wrapper").find(".dataTables_scrollHead").height() || 79
        scroll_border = (::Element.find("##{id}_wrapper").find(".dataTables_scroll").outer_height(true) || 3) - (::Element.find("##{id}_wrapper").find(".dataTables_scroll").height() || 1)
        return "#{other_params[:height] - scroll_head_height - scroll_border}px"
      end
    end
    thead = ::Element.find("##{id} > thead")
    if thead && thead.offset
      top = thead.offset.top
      window_height = `window.innerHeight`
      if top > window_height
        # why sometime it is render below crm settings ?
        top -= window_height
      end
      return "calc(100vh - #{top + thead.height + 2}px)" # Dont't know why we need + 2px ... some border ?
    end
    return "calc(100vh - #{150}px)" # TODO: find a better way
  end

  def styled_column_defs
    return [] unless klass.parent.feature_enabled?('Dynamic::Datatable::Style::Feature')
    column_defs = []
    visible_columns.each_with_index do |col, index|
      created_cell = col.styled_cell_class_callback
      next unless created_cell
      column_defs << {
        targets: index + 1,
        createdCell: created_cell
      }
    end
    return column_defs
  end

  def styled_row_callback
    return nil unless klass.parent.feature_enabled?('Dynamic::Datatable::Style::Feature')
    return nil unless klass.respond_to?(:row_styles)
    row_styles = klass.row_styles
    return nil if row_styles.empty?
    compiled_styles = compile_row_styles(row_styles)
    return nil if compiled_styles.empty?
    component = self
    result_lambda = lambda do |row, data, data_index|
      css_classes = component.compute_row_css_classes(compiled_styles, data)
      if css_classes.present?
        `#{row}.className += ' ' + #{css_classes}`
        `
          var cells = #{row}.getElementsByTagName('td');
          for (var i = 0; i < cells.length; i++) {
            cells[i].className += ' ' + #{css_classes};
          }
        `
      end
    end
    return result_lambda
  end

  def compile_row_styles(row_styles)
    StyleRuleEvaluator.instance.compile_css_styles(row_styles)
  end

  def compute_row_css_classes(compiled_styles, data)
    StyleRuleEvaluator.instance.compute_css_classes(compiled_styles, data).join(' ')
  end

  def column_settings
    result = [{
      name: '',
      target: 0,
      orderable: false,
      searchable: false,
    }]

    visible_columns.each_with_index do |col, i| # We create the table with all the columns and then we manage their visibility through search_query[:column]
      s = {
        width: (search_query_width || other_params[:column_widths]).try(:[],col.name) || "150px",
        name: col.name,
        data: col.name,
        target: i + 1,
        orderable: true, # default is true but it is better to be redoundant
      }

      s[:className] = 'cell-editable' if col.editable?
      s[:className] = "#{s[:className]} cell-without-padding" if col.render_sub_table?
      align = col.respond_to?(:cell_align_class) && col.cell_align_class
      s[:className] = "#{s[:className]} #{align}".strip if align

      s[:render] = col.render_cell_method if col.render_cell_method

      result << s
    end

    return result
  end

  def columns_default()
    return [
      {
        targets: 0,
        data: nil.to_n,
        orderable: false,
        searchable: false,
        className: 'select-checkbox',
      },
      { defaultContent: "", targets: "_all" } # null or undefined cell values are replaced by an empty string for _all culumns
    ]
  end

  def visible_columns
    result = []
    @col_order ||= search_query_columns || []
    @col_order&.each do |name|
      c = klass.datatable_column_by_name[name]
      result << c if c
    end
    return result
  end

  def locked_index
    names = visible_columns.map(&:name)
    anchor_name = other_params[:locked_column] || search_query_locked
    idx = names.index(anchor_name)
    return 1 unless idx
    idx + 1
  end

  def locked_right_index
    names = visible_columns.map(&:name)
    anchor_name = other_params[:locked_column_right] || search_query_locked_right
    idx = names.index(anchor_name)
    return 0 unless idx
    names.length - idx - 1
  end

  def header_callback( thead, data, start, end_, display )
    #puts "test header callback"
  end

  def remove_order_listeners
    ::Element.find("##{id}_wrapper .dataTables_scrollHead th").off(:click).off(:keypress)
  end

  def init_cell_edit
    ::Element.find("##{id}_wrapper tbody").on(:click, 'td.cell-editable') do |event|
      next if event.target.first.is?('A')

      @cell = cell_for_edit(event.current_target)
      next unless @cell

      event.stop_propagation

      focus_later('.cell-editor input.form-control') # because focus must be initiated by click
      mutate

      edit_cell!(@cell)
    end
  end

  def cell_for_edit(td)
    col = column_for_edit(td)
    return unless col&.editable?
    return cell_from_td(td)
  end

  def column_for_edit(td)
    parent_td = td.closest('.sub_table').closest('td')
    parent_td = td if parent_td.length == 0
    col = column(parent_td)
    return unless col
    return klass.datatable_column_by_name[col.name]
  end

  def cell_from_td(td)
    result = cell(td)
    result.node = td.to_n # because it can be nil when td is a sub_table td
    return result
  end

  def init_cell_hover
    ::Element.find("##{id}_wrapper tbody").on(:mouseenter, 'td:not(.select-checkbox)') do |event|
      td = event.current_target
      next if td.children('.sub_table').length > 0
      after(0.5) do #we add some delay to prevent changing DOM constantly
        if td.is(":hover")
          td.attr('title', td.text())
        end
      end
    end
  end

  def init_action_click
    ::Element.find("##{id}_wrapper").off(:click, 'a[data-action-click]')
    ::Element.find("##{id}_wrapper").on(:click, 'a[data-action-click]') do |event|
      event.prevent_default
      event.stop_propagation
      target = ::Element[event.current_target.to_n]
      next if target.has_class?('disabled')
      action_click!({
        action: target.attr('data-action-click'),
        record_id: target.attr('data-record-id'),
        record_type: target.attr('data-record-type'),
        column_name: target.attr('data-column-name'),
        trigger_name: target.attr('data-trigger-name'),
        target: target
      })
    end
  end


  def add_dt_classes
    unless dt_classes.nil?
      if dt_classes.class == Hash
        dt_classes.each do |target, classes|
          ::Element["##{id}_wrapper .#{target}"].addClass(classes)
        end
      end
      if dt_classes.class == String
        ::Element["##{id}_wrapper"].addClass(dt_classes)
      end
    end
  end

  def init_select_rows
    @all_selected = false
    @selected_rows ||= Set.new
    @selected_rows.clear
    @last_clicked_index = nil
    self.jq_node.off(:click, 'tbody .select-checkbox')
    self.jq_node.on(:click, 'tbody .select-checkbox') do |event|
      handle_checkbox_click(event)
    end
  end

  def handle_checkbox_click(event)
    event.stop_propagation
    current_tr = event.target.closest('tr')
    current_row_index = @table.JS.row(current_tr.to_n).JS.index()
    if event.shift_key && @last_clicked_index
      select_range(current_row_index)
      `document.getSelection().removeAllRanges()`
    else
      dt_row = @table.JS.row(current_tr.to_n)
      if row_selected?(dt_row)
        deselect_row(dt_row)
      else
        select_row(dt_row)
      end
      @last_clicked_index = current_row_index
    end
  end

  def row_selected?(dt_row)
    in_set = @selected_rows.include?(row_id_of(dt_row))
    @all_selected ? !in_set : in_set
  end

  def row_id_of(dt_row)
    ::Element[dt_row.JS.node()].attr('id')
  end

  def select_row(dt_row)
    row_id = row_id_of(dt_row)
    if @all_selected
      @selected_rows.delete(row_id)
    else
      @selected_rows << row_id
    end
    dt_row.JS.select()
  end

  def deselect_row(dt_row)
    row_id = row_id_of(dt_row)
    if @all_selected
      @selected_rows << row_id
    else
      @selected_rows.delete(row_id)
    end
    dt_row.JS.deselect()
  end

  def select_range(current_index)
    visible_indices = @table.JS.rows(`{ order: 'current' }`).JS.indexes().JS.toArray()
    start_pos = visible_indices.index(@last_clicked_index)
    end_pos = visible_indices.index(current_index)
    return unless start_pos && end_pos
    low, high = [start_pos, end_pos].minmax
    range_indices = visible_indices[low..high]
    range_indices.each do |idx|
      dt_row = @table.JS.row(idx)
      select_row(dt_row) unless row_selected?(dt_row)
    end
  end

  def reset_selection
    @all_selected = false
    @selected_rows&.clear
    @last_clicked_index = nil
    rows&.deselect
    self.jq_node.trigger('reset-selection.crm.datatable')
  end

  def all_selected?
    @all_selected
  end

  def selected_rows_ids
    @selected_rows.to_a
  end

  def any_selected?
    @all_selected || @selected_rows.any?
  end

  def many_selected?
    @all_selected || @selected_rows.length > 1
  end

  def show_context_menu(event)
    @context_menu_position = {x: event.page_x, y: event.page_y}
    @context_menu_element = ::Element[event.target.to_n]
    @context_menu_element = @context_menu_element.closest('td') unless @context_menu_element.is?('td')
    mutate
  end

  def selected_column_text(column)
    return [] unless any_selected?

    values = []

    for_each_selected_row_in_page do |dt_row|
      text = cell(dt_row.JS.node(), "#{column.name}:name").data

      values << text if text.present?
    end

    values
  end

  def for_each_selected_row_in_page
    if @all_selected
      rows.indexes.each do |i|
        dt_row = @table.JS.row(i)
        yield(dt_row) if row_selected?(dt_row)
      end
    else
      @selected_rows.each do |row_id|
        dt_row = @table.JS.row("##{row_id}")
        yield(dt_row) if dt_row.JS.node()
      end
    end
  end

  def context_menu
    return unless @context_menu_position
    col = column_for_edit(@context_menu_element)
    return unless col
    ContextMenu(position: @context_menu_position) do
      protocols = col.klass.protocols_for_attributes[col.method_name.to_sym] || []
      if @context_menu_element.has_class?('cell-editable')
        dropdown_item_for_edit_cell
      end
      value = @context_menu_element.first('a').text
      record_params = record_data_for_link(col.klass)

      if many_selected?
        if protocols.include?('mailto') && show_dropdown_item_for_feature?('Dynamic::MailHosting::Feature', col.klass.parent)
          dropdown_email_item_for_selected(col, record_params)
        end
      else
        protocols.each do |prot|
          dropdown_item_for_protocol(prot, value, record_params)
          if prot == 'http'
            dropdown_item_for_open_in_new_tab(value)
          end
        end
        if protocols.any?
          dropdown_item_for_copy_url(value)
        end
        download_path =  @context_menu_element.find('[data-download-path]').attr('data-download-path')
        if download_path
          dropdown_item_for_download_attachment(download_path)
          dropdown_item_for_copy_attachment_url(App.location.protocol + "://" + App.location.hostname + download_path)
          dropdown_item_for_open_in_new_tab(download_path)
        end
      end
      if any_selected?
        dropdown_item_for_submit_all
        dropdown_item_for_new_merge_setting if show_merge_setting_dropdown_item?(col)
        dropdown_item_for_new_copy_run if show_copy_run_dropdown_item?(col)
        dropdown_item_for_export_all if show_export_setting_dropdown_item?(col)
        dropdown_item_for_multiple_smses(col.klass.parent) if many_selected? && protocols.include?('sms') && show_dropdown_item_for_feature?('Dynamic::Sms::Feature', col.klass.parent)
        dropdown_item_for_delete_all
      end
      extra = props[:extra_menu_items] || []
      if extra.any?
        DIV(class: 'dropdown-divider')
        extra.each do |item|
          BUTTON(class: 'btn btn-link dropdown-item') do
            I(class: "#{item[:icon]} fa-fw pr-2") if item[:icon]
            SPAN { item[:label] }
          end.on(:click) do |e|
            e.prevent_default
            @context_menu_position = nil
            @context_menu_element  = nil
            if item[:link]
              side = item[:panel]
              param_key = "#{side[0]}p"
              App.history.push(App.location.add_params(param_key => item[:link]))
            end
            mutate
          end
        end
      end
    end.on(:hidden) do
      @context_menu_position = nil
      @context_menu_element = nil
      mutate
    end
  end

  def lock_menu
    return unless @lock_menu_position
    col_name = @lock_menu_column.name
    in_left_zone = column_in_left_lock_zone?(col_name)
    in_right_zone = column_in_right_lock_zone?(col_name)
    ContextMenu(position: @lock_menu_position) do
      if in_left_zone
        A(href: '#', class: 'dropdown-item') do
          I(class: 'fas fa-unlock fa-fw pr-2') {}
          I18n.t('crm.datatable.unlock')
        end.on(:click) do |event|
          event.prevent_default
          lock_column(nil)
          column_locked!(nil)
        end
      elsif in_right_zone
        A(href: '#', class: 'dropdown-item') do
          I(class: 'fas fa-unlock fa-fw pr-2') {}
          I18n.t('crm.datatable.unlock')
        end.on(:click) do |event|
          event.prevent_default
          lock_right_column(nil)
          column_locked_right!(nil)
        end
      else
        A(href: '#', class: 'dropdown-item') do
          I(class: 'fas fa-arrow-left fa-fw pr-2') {}
          I18n.t('crm.datatable.lock_left')
        end.on(:click) do |event|
          event.prevent_default
          anchor_idx = visible_columns.index { |c| c.name == @lock_menu_column.name }
          last_left = anchor_idx && anchor_idx > 0 ? visible_columns[anchor_idx - 1] : nil
          lock_column(last_left)
          column_locked!(last_left ? @lock_menu_column.name : nil)
        end
        A(href: '#', class: 'dropdown-item') do
          I(class: 'fas fa-arrow-right fa-fw pr-2') {}
          I18n.t('crm.datatable.lock_right')
        end.on(:click) do |event|
          event.prevent_default
          anchor_idx = visible_columns.index { |c| c.name == @lock_menu_column.name }
          first_right = anchor_idx && anchor_idx + 1 < visible_columns.length ? visible_columns[anchor_idx + 1] : nil
          lock_right_column(first_right)
          column_locked_right!(first_right ? @lock_menu_column.name : nil)
        end
      end
    end.on(:hidden) do
      @lock_menu_position = nil
      @lock_menu_column = nil
      mutate
    end
  end

  def column_in_left_lock_zone?(col_name)
    anchor_name = other_params[:locked_column] || search_query_locked
    return false unless anchor_name
    names = visible_columns.map(&:name)
    col_idx = names.index(col_name)
    anchor_idx = names.index(anchor_name)
    return false unless col_idx && anchor_idx
    col_idx < anchor_idx
  end

  def column_in_right_lock_zone?(col_name)
    anchor_name = other_params[:locked_column_right] || search_query_locked_right
    return false unless anchor_name
    names = visible_columns.map(&:name)
    col_idx = names.index(col_name)
    anchor_idx = names.index(anchor_name)
    return false unless col_idx && anchor_idx
    col_idx > anchor_idx
  end

  def show_dropdown_item_for_feature?(name, schema_const)
    return false unless schema_const
    schema_const.feature_enabled?(name)
  end

  def dropdown_item_for_edit_cell
    Link('#edit', class: 'dropdown-item') do
      I(class: 'fas fa-pen fa-fw pr-4') {}
      I18n.t('shared.edit')
    end.on(:click) do |event|
      event.prevent_default
      if any_selected?
        @column_for_edit_all = column_for_edit(@context_menu_element)
        if @column_for_edit_all && !@column_for_edit_all.name.include?('.')
          after(0.1) do
            mutate
            ::Element['#edit-all-modal'].modal('show')
          end
          params = {
            method_name: @column_for_edit_all.method_name,
          }
          edit_all!(params, @all_selected, @selected_rows)
        end
      else
        @cell = cell_for_edit(@context_menu_element)
        edit_cell!(@cell) if @cell
      end
    end
  end

  def dropdown_item_for_multiple_smses(parent_klass)
    Link('#multiple_smses', class: 'dropdown-item') do
      I(class: 'fas fa-sms fa-fw pr-4') {}
      I18n.t('shared.mass_send')
    end.on(:click) do |event|
      event.prevent_default
      @column_for_edit_all = column_for_edit(@context_menu_element)
      next unless @column_for_edit_all
      schema_name = parent_klass.name.split('::').last
      sms_klass_name = "#{parent_klass.name}::Sms"
      phone_number_attribute_name = parent_klass.sms_phone_number_attribute_name_for_sms
      Dynamic::Form.with_action(:submit_all).where(
        klass_name: sms_klass_name,
        source_klass_name: sms_klass_name,
        schema_id: schema_name
      ).includes(elements: 1).first do |response|
        after(0.1) do
          ::Element['#edit-all-modal'].modal('show')
        end
        params = {
          association_names: @column_for_edit_all.path,
          form_id: response.id,
          on_conflict_element_id: response.elements.detect {|e| e.attribute_name == phone_number_attribute_name}&.id
        }
        edit_all!(params, @all_selected, @selected_rows)
      end
    end
  end

  def dropdown_item_for_submit_all
    Link('#submit_all', class: 'dropdown-item') do
      I(class: 'fas fa-link fa-fw pr-4') {}
      I18n.t('activerecord.values.dynamic/form.actions.submit_all')
    end.on(:click) do |event|
      event.prevent_default
      if any_selected?
        @column_for_edit_all = column_for_edit(@context_menu_element)
        if @column_for_edit_all
          after(0.1) do
            mutate
            ::Element['#edit-all-modal'].modal('show')
          end
          params = {
            association_names: @column_for_edit_all.path,
            target_klass: @column_for_edit_all.klass,
            root_klass: @column_for_edit_all.root_klass,
          }
          edit_all!(params, @all_selected, @selected_rows)
        end
      else
        @cell = cell_for_edit(@context_menu_element)
        edit_cell!(@cell) if @cell
      end
    end
  end

  def dropdown_item_for_new_merge_setting
    Link('#edit', class: 'dropdown-item') do
      I(class: 'fas fa-object-group fa-fw pr-3') {}
      I18n.t('shared.merge')
    end.on(:click) do |event|
      event.prevent_default
      merge_all!(@all_selected, selected_rows_ids)
    end
  end

  def show_merge_setting_dropdown_item?(col)
    return false unless show_dropdown_item_for_feature?('Dynamic::Merge::Feature', col.klass.parent)
    return User.current.can_create?("#{col.klass.parent.name}::R::Merge::Setting")
  end

  def dropdown_item_for_new_copy_run
    Link('#copy', class: 'dropdown-item') do
      I(class: 'fas fa-clone fa-fw pr-3') {}
      I18n.t('crm.copy.context_menu.run')
    end.on(:click) do |event|
      event.prevent_default
      copy_all!(@all_selected, selected_rows_ids)
    end
  end

  def show_copy_run_dropdown_item?(col)
    return false unless show_dropdown_item_for_feature?('Dynamic::Copy::Feature', col.klass.parent)
    return User.current.can_create?("#{col.klass.parent.name}::R::Copy::Setting")
  end

  def dropdown_item_for_delete_all
    Link('#delete', class: 'dropdown-item') do
      I(class: 'fas fa-trash fa-fw pr-4') {}
      I18n.t('shared.delete')
    end.on(:click) do |event|
      event.prevent_default
      delete_all!(@all_selected, @selected_rows)
    end
  end

  def dropdown_email_item_for_selected(col, params = {})
    dropdown_item_for_protocol(
      'mailto',
      '',
      params,
    ).on(:jq_click) do |event, callback_update|
      selected_emails = selected_column_text(col).join(',')

      if selected_emails.present?
        callback_update.call(:value, selected_emails)
      else
        event.stop_propagation
      end
    end
  end

  def dropdown_item_for_export_all
    Link('#export_all', class: 'dropdown-item') do
      I(class: 'fas fa-file-export fa-fw pr-4') {}
      I18n.t('shared.export')
    end.on(:click) do |event|
      event.prevent_default
      after(0.1) do
        mutate
        ::Element['#export-all-modal'].modal('show')
      end
      export_all!
    end
  end

  def show_export_setting_dropdown_item?(col)
    return false unless show_dropdown_item_for_feature?('Dynamic::Export::Feature', col.klass.parent)
    return User.current.can_create?("#{col.klass.parent.name}::R::Export::Setting")
  end

  def dropdown_item_for_download_attachment(path)
    link_params = {class: 'dropdown-item', download: true}
    A(href: path, **link_params) do
      I(class: "fas fa-download fa-fw pr-3") {}
      I18n.t("shared.download")
    end
  end

  def dropdown_item_for_copy_url(url)
    link_params = {class: 'dropdown-item', target: '_blank'}
    A(href: url, **link_params) do
      I(class: "fas fa-copy fa-fw pr-3") {}
      I18n.t("crm.datatable.copy_url")
    end.on(:click) do |e|
      e.prevent_default
      `navigator.clipboard.writeText(#{url})`
    end
  end

  def dropdown_item_for_copy_attachment_url(url)
    link_params = {class: 'dropdown-item', target: '_blank'}
    A(href: url, **link_params) do
      I(class: "fas fa-copy fa-fw pr-3") {}
      I18n.t("crm.datatable.copy_document_url")
    end.on(:click) do |e|
      e.prevent_default
      `navigator.clipboard.writeText(#{url})`
    end
  end

  def dropdown_item_for_open_in_new_tab(path)
    link_params = {class: 'dropdown-item', target: '_blank'}
    A(href: path, **link_params) do
      I(class: "fas fa-share-square fa-fw pr-3") {}
      I18n.t("crm.datatable.open_in_new_tab")
    end
  end

  def record_data_for_link(current_klass)
    {
      "x-record-type" => current_klass.to_s,
      "x-record-id" => record_id(cell_from_td(@context_menu_element)),
    }
  end

  def timestamp
    @@timestamp ||= 0
    @@timestamp += 1
  end

end
