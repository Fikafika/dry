# example:
# InfiniteScroll(DIV, class: 'list-group', items: D::Uneek::Contact) do |record|
#   DIV(class: 'list-group-item') do
#     record.last_name
#   end
# end

def InfiniteScroll(component, params = {}, &block)
  items = params.delete(:items)
  show_loader = params.delete(:show_loader)
  reload = params.delete(:reload)
  on_ready = params.delete(:on_ready)

  if component.class.name == 'Hyperstack::Component::Element'
    component_ = component.element_type.upcase
  else
    component_ = component.upcase
  end

  InfiniteScroller({
    component: component_,
    component_params: params,
    items: items,
    item_render: block,
    show_loader: show_loader,
    reload: reload,
    on_ready: on_ready,
  })
end

class InfiniteScroller < HyperComponent

  param :component, default: 'DIV'
  param :component_params, default: {}
  param :items
  param :loader, default: nil

  param :item_render, default: nil

  param :layout, default: nil
  param :delegate, default: nil

  param :show_loader, default: true

  param :reload, default: nil
  param :on_ready, default: nil
  collect_other_params_as :other_params

  @initial_fill = true

  before_mount do
    init
  end

  after_mount do
    on_ready.call(self) if on_ready
    panel = ::Element.find(self.dom_node).parents('.side-panel')
    if panel.length > 0
      panel.on(:scroll) do |event|
        scrolling(event)
      end
    end
  end

  before_new_params do |next_props|
    if next_props[:items].try(:klass) != items.try(:klass) || !same_scope?(next_props[:items], items) || next_props[:reload] != reload
      init
    end
  end

  def remove_record(id)
    @records_per_page.each_value do |records|
      records.delete_if { |r| r.id == id }
    end
    mutate
  end

  def prepend_record(record)
    @records_per_page.each_value { |records| records.delete_if { |r| r.id == record.id } }
    first_page = @records_per_page.keys.min || 1
    @records_per_page[first_page] ||= []
    @records_per_page[first_page].unshift(record)
    mutate
  end

  def insert_record_at(record, target_ticket_id, direction = "before")
    @records_per_page.each_value { |records| records.delete_if { |r| r.id == record.id } }
    first_page = @records_per_page.keys.min || 1
    @records_per_page[first_page] ||= []

    if target_ticket_id
      idx = @records_per_page[first_page].index { |r| r.id == target_ticket_id }
      idx ||= @records_per_page[first_page].length
      idx += 1 if direction == "after"
      @records_per_page[first_page].insert(idx, record)
    else
      @records_per_page[first_page].push(record)
    end
    mutate
  end

  def loaded_records
    @records_per_page.values.flatten
  end

  def same_scope?(relation1, relation2)
    s1 = relation1.try(:scope) ? relation1.scope.dup : {}
    s2 = relation2.try(:scope) ? relation2.scope.dup : {}
    s1.delete(:page)
    s2.delete(:page)
    return s1 == s2
  end

  def init
    @page = 0
    @records_per_page = {}
    @finished = false
  end

  render do
    send(component, component_params_with_overflow) do

      find_next_page if @page == 0

      if item_render
        (1..@page).each do |page|
          @records_per_page[page]&.each do |record|
            item_render.call(record).to_n
          end
        end
      elsif delegate
        (1..@page).each do |page|
          @records_per_page[page]&.each do |record|
            layout.render_delegate(delegate, record: record)
          end
        end
      end
      render_loader unless finished?
    end.on(:scroll) do |event|
      scrolling(event)
    end
  end

  def scrolling(event)
    @initial_fill = false
    return if unmounted? || !::Element.find(self.dom_node).is(':visible') || finished? || loading?

    if height_from_bottom(event.target) < (placeholder_height + foresight)
      find_next_page
    end
  end

  def find_next_page
    return unless items
    @page += 1
    @request = items.page(@page).all do |records|
      if records.empty?
        finish
        next
      end
      original_length = records.to_a.length
      existing_ids = @records_per_page.values.flatten.map(&:id)
      new_records = records.to_a.reject { |r| existing_ids.include?(r.id) }
      @records_per_page[@page] = new_records
      if page_size
        finish if original_length < page_size
      end
      mutate
      fill_until_scrollable
    end
  end

  def page_size
    other_params[:per_page] || component_params[:per_page]
  end

  def height_from_bottom(target)
    t = ::Element.find(target.to_n)
    return t.prop('scrollHeight') - t.prop('scrollTop') - t.height
  end

  def finished?
    @finished
  end

  def loading?
    @request&.loading?
  end

  def finish
    mutate @finished = true
  end

  def render_loader
    return if finished?
    return unless show_loader
    DIV(style: {height: "#{placeholder_height}px"}) do
      loader.create_element.render if loader
    end
  end

  def placeholder_height
    other_params[:placeholder_height] || component_params[:placeholder_height] || 300
  end

  def foresight
    other_params[:foresight] || component_params[:foresight] || 100
  end

  def fill_until_scrollable
    return unless @initial_fill
    return if finished?
    return if loading?
    element = self.jq_node

    if element.prop("scrollHeight") <= element.prop("clientHeight")
      find_next_page
    else
      @initial_fill = false
    end
  end

  def component_params_with_overflow
    result = component_params
    result[:style] ||= {}
    result[:style] = {overflowY: 'auto', maxHeight: '100%', overflowX: 'hidden'}.merge(result[:style])

    return result
  end

end
