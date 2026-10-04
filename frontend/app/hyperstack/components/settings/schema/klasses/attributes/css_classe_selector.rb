# backtick_javascript: true

class CssClassSelector < HyperComponent
  include ::Form::Element::TomSelect

  param :value
  param :style_type
  fires :change

  COLORS = {
    'primary'         => 'primary',
    'secondary'       => 'secondary',
    'success'         => 'success',
    'danger'          => 'danger',
    'warning'         => 'warning',
    'info'            => 'info',
    'light'           => 'light',
    'dark'            => 'dark',
    'white'           => 'white',
    'pal-blue-gray'   => 'pal-blue-gray',
    'pal-dark-teal'   => 'pal-dark-teal',
    'pal-dark-green'  => 'pal-dark-green',
    'pal-dark-blue'   => 'pal-dark-blue',
    'pal-dark-purple' => 'pal-dark-purple',
    'pal-dark-red'    => 'pal-dark-red',
    'pal-dark-orange' => 'pal-dark-orange',
    'pal-mustard'     => 'pal-mustard'
  }.freeze

  def use_tom_select?
    true
  end

  def possible_values
    available_classes.map do |css_class, label|
      { value: css_class, label: label }
    end
  end

  def change_value(val)
    safe_val = Array(val).first.to_s
    change!(safe_val)
  end

  def select_element
    jq_node
  end

  def selected_values
    return [] if value.blank?
    found_pair = available_classes.find { |v, _| v == value }
    label = found_pair ? found_pair.last : value

    [{ value: value, label: label }]
  end

  def must_update_tom_select_values?
    return false if @previous_val == value
    @previous_val = value
    true
  end

  def prefix
    case style_type
    when 'badge'     then 'badge-'
    when 'row_color' then 'bg-'
    when 'icon'      then 'text-'
    when 'button'    then 'btn-'
    else                  'bg-'
    end
  end

  def available_classes
    @_available_classes_cache ||= {}
    @_available_classes_cache[style_type] ||= COLORS.map do |key, label|
      ["#{prefix}#{key}", label]
    end
  end

  render do
    SELECT(class: 'form-control', defaultValue: value.to_s) do
      OPTION(value: '') { I18n.t('shared.none_f') }
      available_classes.each do |css_class, label|
        OPTION(value: css_class) { label }
      end
    end
  end

  def tom_select_options
    is_icon_style = (style_type == 'icon')
    template = lambda do |data, escape|
      d = Native(data)
      container = ::Element.new('div').add_class('d-flex align-items-center')
      css_classes = is_icon_style ? "fa fa-circle mr-2 #{d[:value]}" : "d-inline-block rounded mr-2 p-1 #{d[:value]}"
      tag_type    = is_icon_style ? 'i' : 'span'
      color_box = ::Element.new(tag_type).add_class(css_classes)
      label     = ::Element.new('span').text(d[:value])
      container.append(color_box).append(label).prop('outerHTML')
    end.to_n
    {
      create: true,
      maxItems: 1,
      render: {
        option: template,
        item: template,
      }
    }
  end

  def record_is_invalid_changed?; false; end
  def form; end
  def record; end
end