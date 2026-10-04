class Crm::Datatable::ColumnHeader < HyperComponent

  param :klass
  param :column
  param :sort_index, default: nil

  fires :click_delete
  fires :column_param
  fires :show_lock_menu
  fires :reorder

  render() do
    @title = nil
    DIV(class: 'd-flex flex-row', style: {marginBottom: "0.3rem"}) do
      DIV(class: "align-self-start") do
        DIV(class: 'btn btn-sm btn-transparent-light-yiq shadow-none') do
          SPAN(class: 'fa lock-icon') do
          end
        end.on(:click) do |event|
          event.stop_propagation
          show_lock_menu!(column: column, x: event.page_x, y: event.page_y)
        end
      end
      DIV(class: 'flex-grow-1 text-nowrap') do
        SPAN(class: 'text-overflow-dynamic-container') do
          SPAN(class: 'text-overflow-dynamic-ellipsis text-center column-title', title: title) do
            SPAN { title }
          end.on(:click) do |event|
            s = ::Element.find(event.current_target.to_n).closest('.sorting_asc, .sorting_desc')
            direction = s.has_class?('sorting_asc') ? 'desc' : 'asc'
            reorder!({column: column, direction: direction, multi: event.shift_key})
          end
          SPAN(class: 'column-order') do
          end
        end
      end
      DIV(class: 'align-self-end') do
        if sort_index
          SPAN(class: 'badge badge-secondary rounded-circle justify-content-center p-0 z-3 w-50 pb-1') do
            sort_index.to_s
          end
        end
        DIV(class: 'btn btn-sm btn-transparent-light-yiq shadow-none') do
          SPAN(class: 'fa fa-times') do
          end
        end.on(:click) do |event|
          event.stop_propagation
          click_delete!(column)
        end
      end
    end
  end

  def title
    @title ||= column.human_path.join(' > ')
  end

end
