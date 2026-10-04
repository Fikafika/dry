# backtick_javascript: true

module Crm::Datatable::SummaryRenderer

  def init_summary
    wrapper = Element.find("##{id}_wrapper")
    return unless wrapper.length > 0
    wrapper.off('click.summary')
    wrapper.off('change.summary')
    wrapper.off('blur.summary')
    wrapper.off('mousedown.summary')

    wrapper.on('click.summary', '.summary-display') do |event|
      event.stop_propagation
      event.prevent_default
      cell = Element[event.current_target].closest('[data-summary-col]')
      next if cell.empty?
      show_select(cell)
    end

    wrapper.on('change.summary', '.summary-op-select') do |event|
      event.stop_propagation
      select_el = Element[event.current_target]
      col_name = select_el.attr('data-summary-select')
      new_op = select_el.value
      next unless col_name.present? && new_op.present?
      hide_select(select_el.closest('[data-summary-col]'))
      col = visible_columns.detect { |c| c.name.to_s == col_name }
      summary_changed!(col_name, new_op, col&.default_summary_operation)
    end

    wrapper.on('blur.summary', '.summary-op-select') do |event|
      el = Element[event.current_target]
      after(0.15) do
        cell = el.closest('[data-summary-col]')
        next if cell.empty?
        hide_select(cell)
      end
    end

    wrapper.on('mousedown.summary', '.summary-footer-content') do |event|
      event.stop_propagation
    end
  end

  def cleanup_summary
    wrapper = Element.find("##{id}_wrapper")
    return unless wrapper.length > 0
    wrapper.off('click.summary')
    wrapper.off('change.summary')
    wrapper.off('blur.summary')
    wrapper.off('mousedown.summary')
  end

  def render_footer_cells(tfoot_native, summaries)
    tfoot_el = Element[tfoot_native]
    visible_columns.each do |col|
      col_name = col.name.to_s
      current_op = current_op_for_column(col)
      value = extract_summary_value(summaries, col_name, current_op)
      html = build_cell_html(col_name, col.summary_operations, current_op, value)
      tfoot_el.find("th[data-summary-col='#{col_name}']").html(html)
    end
  end

  private

  def show_select(cell)
    cell.find('.summary-display').add_class('invisible')
    cell.find('.summary-select-wrapper').remove_class('invisible').add_class('visible')
    cell.find('select').focus
  end

  def hide_select(cell)
    cell.find('.summary-display').remove_class('invisible')
    cell.find('.summary-select-wrapper').remove_class('visible').add_class('invisible')
  end

  def extract_summary_value(summaries, col_name, current_op)
    col_data = Native(summaries)[col_name]
    return nil unless col_data
    col_data = Native(col_data)
    value = col_data[current_op]
    return value unless value.nil?
    first_key = `Object.keys(#{col_data.to_n})[0]`
    first_key ? col_data[first_key] : nil
  end

  def current_op_for_column(col)
    section = search_query[search_query_key] || {}
    summary = section[:summary] || {}
    config = summary[col.name.to_s]
    ops = case config
      when Hash then config[:ops] || []
      when Array then config
      else []
      end
    Array(ops).first || col.default_summary_operation
  end

  def format_value(value)
    return '' if value.nil?
    `(typeof #{value} === 'number') ? #{value}.toLocaleString() : String(#{value})`
  end

  def build_cell_html(col_name, available_ops, current_op, value)
    symbol = I18n.t("crm.datatable.summary.operations.#{current_op}.symbol")
    formatted = format_value(value)
    value_span = formatted.to_s.empty? ? '' : "<span class=\"summary-value\">#{formatted}</span>"
    options_html = available_ops.map do |op|
      selected = (op == current_op) ? ' selected' : ''
      op_symbol = I18n.t("crm.datatable.summary.operations.#{op}.symbol")
      op_label = I18n.t("crm.datatable.summary.operations.#{op}.label")
      "<option value=\"#{op}\"#{selected}>#{op_symbol} #{op_label}</option>"
    end.join
    <<~HTML
      <div class="position-relative w-100">
        <div class="summary-display d-flex justify-content-between align-items-center cursor-pointer">
          #{value_span}
          <span class="summary-symbol">#{symbol}</span>
        </div>
        <div class="summary-select-wrapper d-flex align-items-center position-absolute w-100 h-100 z-1 invisible" style="top:0;left:0;">
          <select class="form-control form-control-sm py-0 w-100 h-100 summary-op-select" data-summary-select="#{col_name}">
            #{options_html}
          </select>
        </div>
      </div>
    HTML
  end
end