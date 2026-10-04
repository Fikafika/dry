class Crm::SearchInput < HyperComponent
  include Hyperstack::Router::Helpers

  param :search_query
  param :draw, default: nil

  fires :launch_search

  after_new_params do
    if search_query && @previous_search_query_q != search_query[:q]
      @input_value = search_query[:q]
      @previous_search_query_q = @input_value
    end
  end

  render() do
    DIV(class: 'input-group flex-fill') do
      INPUT(class: 'form-control', type: 'text', value: @input_value)
      .on(:change) do |evt|
        @input_value = evt.target.value
        mutate
      end
      .on(:key_press) do |event|
        key = event.which
        if key==13
          event.stop_propagation
          event.prevent_default
          launch_query
        end
      end
      DIV(class: 'input-group-append') do
        Link("", class: 'btn input-group-text shadow-none') do
          SPAN(class: 'fa fa-search') do
          end
        end.on(:click) do |event|
          event.stop_propagation
          event.prevent_default
          launch_query
        end
      end
    end
  end

  def launch_query
    if @input_value.present?
      search_query[:q] = @input_value
    else
      search_query.delete(:q)
    end
    @previous_search_query_q = search_query[:q]
    launch_search!
  end

end
