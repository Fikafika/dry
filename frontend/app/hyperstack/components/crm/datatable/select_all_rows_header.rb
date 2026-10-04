class Crm::Datatable::SelectAllRowsHeader < HyperComponent

  param :datatable

  fires :change

  render do
    DIV(class: "form-control-sm px-0") do
      DIV(class: "select-all-rows #{state}") do
      end.on(:click) do |event|
        event.stop_propagation
        @checked ? datatable.rows.deselect : datatable.rows.select
        @checked = !@checked
        change!(@checked)
        mutate
      end
    end
  end

  def state
    if @checked
      indeterminate ? 'indeterminate' : 'selected'
    else
      ''
    end
  end

  def indeterminate
    datatable.rows(selected: true).count != datatable.rows().count
  end

  after_mount do
    datatable.jq_node.on('click', 'tbody .select-checkbox') do |event|
      mutate
    end
    datatable.jq_node.on('reset-selection.crm.datatable') do |event|
      @checked = false
      mutate
    end
  end

end
