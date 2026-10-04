class Crm
  class DatatableWithRowGroup < ::Datatable

    param :id
    param :klass
    param :columns, default: []
    param :group_column, default: 'group'
    param :position_column, default: 'position'
    param :currency, default: nil
    param :additional_cell_lines, default: {}

    collect_other_params_as :other_params

    track_changes [:other_params, :draw]

    fires :init
    fires :row_reorder

    before_mount do
      remove_datatable
    end

    before_unmount do
      remove_datatable
    end

    after_mount do
      init_datatable
      self.jq_node.on(:click, '.collapse-icon') do |e|
        e.stop_propagation
        n = ::Element[e.current_target.to_n].parent.parent
        collapse_group(n)
      end
    end

    after_render do
      if other_params_draw_changed?
        ajax_reload
      end
    end

    render do
      TABLE(id: id, class: "table table-sm table-bordered nowrap crm_table dataTable #{other_params[:className]}") do
        THEAD() do
          TR() do
            if row_reorder?
              TH(key: 'C_0', class: "border-top-0 py-0") do
                I(class: 'p-0 fa fa-fw fa-xs fa-arrows-alt-v')
              end
            end
            visible_columns.each do |col|
              TH(key: col.name, class: "border-top-0 data-column pt-0", "data-attr": col.name) do
                DIV(class: 'd-flex flex-row') do
                  DIV(class: 'flex-grow-1 text-nowrap') do
                    SPAN(class: 'text-overflow-dynamic-container') do
                      title = col.human_name || col.human_path.join(' > ')
                      SPAN(class: 'text-overflow-dynamic-ellipsis text-center column-title', title: title) do
                        title
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end

    private

    def init_datatable
      return if @table

      t = ::Element.find("##{id}")

      set_datatable_err_mode

      @native = @table = t.DataTable(
        settings
      )

      self.jq_node.data('table', Proc.new{ @table })
      self.jq_node.data('get_component', Proc.new{ self })

      workaround_remove_child

      @collapsed = {}

      native_off('row-reorder')
      native_on('row-reorder') do |e, diff, edit|
        row_reorder(e, diff, edit)
      end

      init!(@native)
    end

    def row_reorder(e, diff, edit)
      origin = Native(edit.JS['triggerRow'])

      diff = diff.map{|d| row("#" + Native(d.JS['node']).id) } # convert to Row
      changeds = diff.select{|r| r.data[group_column] == origin.data[group_column]} # keep only row that have same group_id

      return unless changeds.any?

      # compute new positions
      new_attrs = []
      changeds.each_with_index do |c, i|
        new_attrs << {
          id: c.data['id'],
          position_column => i,
        }
      end
      row_reorder!(new_attrs, ->() { ajax_reload })
    end

    def ajax_reload
      clear_caches
      super
    end

    def collapsed?(id)
      @collapsed ||= {}
      return @collapsed[id]
    end

    def collapse_group(group_node)
      group_id = group_node.attr('id') # TODO id should not be record's id
      group_node.find('.collapse-icon').toggle_class('fa-chevron-right')
      @collapsed[group_id] = !@collapsed[group_id]
      descendant_nodes = self.rows(-> (_, d, _) { ancestors_ids[d.JS['id']]&.include?(group_id) }).nodes
      ::Element[descendant_nodes.to_n].toggle
    end

    def settings
      result = {
        ajax: ajax,
        colReorder: {
          fixedColumnsLeft: 1,
          realtime: false,
        },
        columnDefs: columns_default || [],
        columns: column_settings,
        defRender: true,
        dom: "R"+ "<'row no-gutters'<'col-sm-12'tr>>",
        info: false,
        language: I18n.t('datatable'),
        orderCellsTop: false,
        processing: false,
        scrollCollapse: false,
        scrollX: true, # default false
        scrollY: false,
        pager: false,
        autoWidth: false,
        rowId: 'id', # needed for identify a row,
        rowReorder: row_reorder? ? {
          dataSrc: 'row_position',
          dropIsAllowed: drop_contraint,
        } : false,
        paging: false,
      }

      return result
    end

    def ajax
      result = other_params[:ajax] || {}
      result[:dataSrc] = Proc.new do |data|
        compute_row_positions(data)
        data
      end
      return result
    end

    def compute_row_positions(data)
      @data = Array(data).map{|d| ::Hash.new(d)} # TODO don't convert

      row_positions = {}

      @data.each_with_index do |row, i|
        row[:_position_index] = i # secondary value in case of duplicate position
      end

      @data.each do |row|
        row_pos = []
        ancestors_ids[row[:id]].to_a.reverse.each do |id|
          r = by_id[id]
          row_pos << [r[position_column] || @data.length, r[:_position_index]]
        end
        row_pos << [row[position_column] || @data.length, row[:_position_index]]
        row_positions[row[:id]] = row_pos
      end

      sorted_row_positions = row_positions.values.sort

      data.each do |row|
        row_position = sorted_row_positions.index(row_positions[row.JS['id']])
        row.JS['row_position'] = row_position
      end

      data
    end

    def data
      @data
    end

    def columns_default
      result = []

      if row_reorder?
        result << {
          target: 0,
          data: 'row_position',
          orderable: false,
          searchable: false,
          render: Proc.new{ |d| %Q[<span class="d-none">#{d}</span>] } # this column must contain position, why ?
        }
      end

      align_right_target = []
      visible_columns.each_with_index do |c, i|
        if c.format == 'currency'
          align_right_target << i + (row_reorder? ? 1 : 0)
        end
      end

      result << { className: 'text-right', targets: align_right_target }

      result << { defaultContent: "", targets: "_all" } # null or undefined cell values are replaced by an empty string for _all columns
    end

    def column_settings
      result = []

      result << {
        name: 'row_position',
        target: result.length,
        width: "15px",
        orderable: false,
        searchable: false,
        className: 'cursor-move',
      }

      visible_columns.each do |col| # We create the table with all the columns and then we manage their visibility through search_query[:column]
        s = {
          width: compute_column_width(col),
          name: col.name,
          data: col.name,
          target: result.length,
          orderable: false,
        }

        if col.name == klass.name_attribute
          s[:render] = name_attribute_render_cell_method(col)
        elsif additional_cell_lines[col.name]&.any?
          s[:render] = render_cell_method_with_additional_lines(col)
        else
          if col.render_cell_method
            s[:render] = col.render_cell_method
          end
        end

        s[:className] = "#{s[:className]} cell-without-padding" if col.render_sub_table?

        result << s
      end

      return result
    end

    def compute_column_width(col)
      result = column_widths[col.name]
      unless result
        if col.name == klass.name_attribute
          result = '100%'
        end
      end
      return result
    end

    def column_widths
      return @column_widths if @column_widths
      @column_widths = {}
      columns.each do |c|
        next unless c[:width]
        @column_widths[c[:name]] = c[:width]
      end
      return @column_widths
    end

    def name_attribute_render_cell_method(col)
      return lambda do |data, type, row|
        row_id = row.JS['id']
        r = col.render_link_open_panel(klass, row_id, data)
        i = render_space_and_collapse_icon(row_id)
        if additional_cell_lines[col.name]&.any?
          lines = [{
            content: "#{i}#{r}"
          }]
          additional_cell_lines[col.name].each do |setting|
            values = setting[:value_retriever].call(row, col)
            values&.each do |value|
              lines << {
                css_class: setting[:css_class],
                content: "#{i}#{value}",
              }
            end
          end
          next render_cell_with_additional_lines(lines)
        else
          next %Q[#{i}#{r}]
        end
      end
    end

    def render_cell_method_with_additional_lines(col)
      return lambda do |data, type, row|
        d = [{
          content: data
        }]
        additional_cell_lines[col.name].each do |setting|
          values = setting[:value_retriever].call(row, col)
          (values || []).each do |r|
            d << {
              css_class: setting[:css_class],
              content: r,
            }
          end
        end

        if col.render_cell_method
          lines = []
          d.each do |v|
            lines << {
              css_class: v[:css_class],
              content: col.render_cell_method.call(v[:content], type, row)
            }
          end
        else
          lines = d
        end
        next render_cell_with_additional_lines(lines)
      end
    end

    def render_cell_with_additional_lines(lines)
      trs = ''
      lines.each do |h|
        trs += %Q[<div class="border-0 p-0 #{h[:css_class]}">#{h[:content]}</div>]
      end
      return unless trs.present?
      %Q[<div>#{trs}</div>]
    end

    def row_reorder?
      true
    end

    def drop_contraint
      Proc.new do |position, origin, target|
        origin = Native(origin)
        target = Native(target)

        if !target.data
          # hover the end
          last_idx = @data.length - 1
          last_row = row(->(_, d, _){ d.JS['row_position'] == last_idx})
          target = last_row
          next false unless target
          next true if !origin.data[group_column] || ancestors_ids[target.data['id']].include?(origin.data[group_column])
        end

        next origin.data[group_column] == target.data[group_column]
      end
    end

    def show_collapse_column?
      max_depth > 0
    end

    def max_depth
      @max_depth ||= ancestors_ids.values.map(&:length).max || 0
    end

    def render_space_and_collapse_icon(row_id)
      depth = ancestors_ids[row_id].length
      if children_by_id[row_id]&.any?
        return %Q[<i class="collapse-icon fa fa-xs fa-chevron-down cursor-pointer collapse-indent collapse-indent-#{depth}"/></i>]
      else
        return %Q[<span class="collapse-indent collapse-indent-#{depth + 1 }"/></span>]
      end
    end

    def remove_datatable
      return unless @table
      clear().destroy()
      @native = @table = nil
    end

    def visible_columns
      return @visible_columns if @visible_columns
      @visible_columns = []

      columns.each do |col|
        next unless col_name = col[:name]
        root_klass = klass = self.klass
        col_name.split('.').each do |s|
          s = s.gsub('[]', '')
          if a = klass.reflect_on_association(s)
            klass = a.klass
          end
        end
        method_name = col_name.split('.').last
        column_klass = Crm::Datatable::Column.klass_from_method_name(klass, method_name)
        if column_klass.nil?
          column_klass = "#{Crm::Datatable::Column.name}::#{col[:type]}".safe_constantize
        end
        next unless column_klass
        @visible_columns << column_klass.new(
          name: col_name,
          root_klass: root_klass,
          klass: klass,
          method_name: method_name,
          human_name: col[:"human_name_#{I18n.locale}"],
          format: col[:format],
          format_options: format_options[col[:format]],
        )
      end
      return @visible_columns
    end

    def format_options
      {
        'x100_percentage' => { strip_insignificant_zero: true, precision: 2 },
        'currency' => { currency: currency },
      }
    end

    def children_by_id
      return @children_by_id if @children_by_id
      @children_by_id = {}
      data.each do |r|
        next unless r[group_column]
        @children_by_id[r[group_column]] ||= []
        @children_by_id[r[group_column]] << r
      end
      return @children_by_id
    end

    def ancestors_ids
      return @ancestors_ids if @ancestors_ids
      @ancestors_ids = {}
      data.each do |r|
        @ancestors_ids[r[:id]] ||= Set.new
        r_ = r
        while r_ = by_id[r_[group_column]]
          @ancestors_ids[r[:id]] << r_[:id]
        end
      end
      return @ancestors_ids
    end

    def by_id
      return @by_id if @by_id
      @by_id = {}
      data.each{|r| @by_id[r[:id]] = r}
      return @by_id
    end

    def clear_caches
      @by_id = nil
      @children_by_id = nil
      @ancestors_ids = nil
      @max_depth = nil
      @visible_columns = nil
      @data = nil
    end

  end
end
