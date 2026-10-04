# backtick_javascript: true

class InputWithAutocomplete < HyperComponent
  include WithThrottling

  param :search_url, default: nil
  param :term_param, default: 'term'
  param :base_params, default: { select2: true }
  param :http_options, default: {}
  param :template_result, default: nil
  param :process_params, default: nil
  param :process_results, default: nil
  param :autofocus, default: false
  param :prevent_close_on_escape, default: false
  param :convert_selected_item, default: nil
  #TODO param :highlight_first, default: true
  param :return_string, default: false

  collect_other_params_as :others

  fires :change
  fires :key_enter
  fires :key_escape
  fires :search
  fires :focus
  fires :blur
  fires :select

  attr_accessor :menu
  attr_accessor :prevent_blur

  render { content }

  after_mount do
    focus_input if autofocus
  end

  def content
    DIV(container_args) do
      INPUT(input_args).on(:change) do |event|
        change!(event)
      end.on(:focus) do |event|
        @prevent_blur = false
        @menu_open = true
        search(event.target.value)
        mutate
        focus!(event)
        event.target.select
      end.on(:blur) do |event|
        next if @prevent_blur
        close_menu
        blur!(event)
      end.on(:key_up) do |event|
        case event.key_code
        when 13 # enter/tab
          value = @highlighted || (return_string && input_element.value)
          key_enter!(event, value)
        when 27 # escape
          close_menu unless prevent_close_on_escape
          key_escape!(event)
        when 38 # up
          menu.up
        when 40 # down
          menu.down
        when 37,39 # left/right
          # do nothing
        else
          search(event.target.value)
        end
      end.on(:key_down) do |event|
        event.prevent_default if [38,40].include?(event.key_code)
      end.on(:click) do |event|
        event.current_target.select
      end
      render_menu
    end
  end

  def close_menu
    if @menu_open
      mutate @menu_open = false
    end
  end

  def focus_input
    input_element.focus
  end

  def input_element
    self.jq_node.find('input')
  end

  def search(value)
    return unless search_url
    if base_params&.is_a?(Native::Object) # why default value of base_params is a native object ? a bug in hyperstack ?
      url_params = base_params.to_h
    else
      url_params = base_params.dup
    end
    url_params.merge!(term_param => value) if value.present?
    url_params = process_params.call(url_params) if process_params
    url = add_params_to_url(search_url, url_params)
    with_throttling do
      @ajax&.abort
      @ajax = HttpWithCrossDomain.get(url, http_options || {}) do |response|
        if response.ok?
          if process_results
            @items = process_results.call(response.json)
          else
            @items = response.json[:results] rescue []
          end
        else
          # TODO
        end
        mutate
      end
    end

    search!(value)
  end

  def add_params_to_url(url, params)
    url = url + "?" unless url.include?('?')
    url = url + "&" unless url.end_with?('&') || url.end_with?('?')
    url += `$.param(#{params.to_n})`
    return url
  end

  after_update do
    if input_element_rendered
      @previous_top = @top
      @previous_left = @left
      @previous_width = @width

      @top = input_element.offset.top + input_element.outer_height
      @left = input_element.offset.left
      @width = input_element.outer_width
      @z_index = 1000000 # TODO

      mutate if @top != @previous_top || @left != @previous_left || @width != @previous_width
    end
  end

  def render_menu
    Portal(id: 'input-with-autocomplete-portal', parentSelector: '.router-top-level') do
      if @top
        Dropdown(
          show: @menu_open,
          left: @left,
          top: @top,
          width: @width,
          z_index: @z_index + 1,
          items: @items,
          template_result: template_result,
          input: self,
          timestamp: timestamp
        ).on(:select) do |event, item|
          if convert_selected_item
            convert_selected_item.call(item) do |converted_item|
              select!(event, converted_item)
            end
          else
            select!(event, item)
          end
        end.on(:close) do
          @menu_open = false
          after(0.1) do
            mutate if @menu_open == false
          end
        end.on(:highlight) do |item|
          @highlighted = item
        end
      end
    end
  end

  def timestamp
    @timestamp ||= 0
    @timestamp += 1
  end

  def input_element_rendered
    mounted? && input_element.length > 0 && input_element.offset
  end

  def container_args
    result = others.dup
    result.delete(:input_args)
    result.delete(:value)
    result.delete(:nil_value_when_blank)
    result[:class] = "input-with-autocomplete #{result[:class]}"
    return result
  end

  def input_args
    @input_args = others[:input_args] || {}
    @input_args[:autoComplete] ||= 'off'
    @input_args[:autoCorrect] ||= 'off'
    @input_args[:type] ||= 'text'
    return @input_args
  end

  class Dropdown < HyperComponent

    fires :select
    fires :close
    fires :highlight

    param :items
    param :show, default: false
    param :left, default: 0
    param :top, default: 0
    param :width, default: 0
    param :z_index
    param :template_result, default: nil

    param :timestamp, default: false

    param :input, default: nil

    render do
      next unless show && items&.any?

      DIV(class: "border rounded-0 shadow dropdown-menu container p-0 show", style: {maxHeight: '50vh', overflow: 'auto', left: left, top: top, width: width, zIndex: z_index}) do
        items.each do |item| # TODO infinite scroll
          render_item(item).on(:mouse_down) do |event|
            input.prevent_blur = true if input
          end.on(:click) do |event|
            input.prevent_blur = false if input
            select!(event, item)
            close
          end
        end
      end
    end

    def render_item(item)
      if template_result
        DIV(key: "dropdown-item-#{item[:id] || item[:value]}", class: "dropdown-item px-2 cursor-pointer", dangerously_set_inner_HTML: {__html: template_result.call(item)})
      else
        DIV(key: "dropdown-item-#{item[:id] || item[:value]}", class: "dropdown-item px-2 cursor-pointer") do
          item[:text]
        end
      end
    end

    after_mount do
      input.menu = self if input
    end

    def up
      @highlighted_index ||= 0
      @highlighted_index -= 1 unless @highlighted_index == -1
      highlight
    end

    def down
      @highlighted_index ||= -1
      @highlighted_index += 1 unless items && @highlighted_index == items.length - 1
      highlight
    end

    def highlight
      self.jq_node.find(".dropdown-item").remove_class('active')
      self.jq_node.find(".dropdown-item").take(@highlighted_index)&.add_class('active') if @highlighted_index >= 0
      highlight!(highlighted)
    end

    def highlighted
      return nil unless items && @highlighted_index >= 0
      return items[@highlighted_index]
    end

    def close
      @highlighted_index = nil
      close!
    end

  end

end
