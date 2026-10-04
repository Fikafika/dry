# backtick_javascript: true

class GroupDrop < HyperComponent

  param :maxnum, default: 3, type:Integer
  param :variant, default: 'light-yiq', type: String

  render(DIV, class: 'group-drop d-flex flex-nowrap ml-auto flex-shrink-0') do # buttons in this group don't wrap

    # media queries screen xl: 3 buttons
    DIV(class: 'd-none d-xl-flex', role: 'group') do
      maxnum = self.maxnum
      children.each_with_index do |child, i|
        if i < maxnum
          child.render
        end
      end
      if children.length > maxnum
        dropdown do
          children.each_with_index do |child, i|
            if i >= maxnum
              Toolbar::Dropdown::Item(convert_params(child))
            end
          end
        end
      end
    end
    # media queries screen lg: 2 buttons
    DIV(class: 'd-none d-lg-flex d-xl-none', role: 'group') do
      maxnum = 2
      children.each_with_index do |child, i|
        if i < maxnum
          child.render
        end
      end
      if children.length > maxnum
        dropdown do
          children.each_with_index do |child, i|
            if i >= maxnum
              Toolbar::Dropdown::Item(convert_params(child))
            end
          end
        end
      end
    end
    # media queries screen md: 1 button
    DIV(class: 'd-none d-md-flex d-lg-none', role: 'group') do
      maxnum = 1
      children.each_with_index do |child, i|
        if i < maxnum
          child.render
        end
      end
      if children.length > maxnum
        dropdown do
          children.each_with_index do |child, i|
            if i >= maxnum
              Toolbar::Dropdown::Item(convert_params(child))
            end
          end
        end
      end
    end

    # TODO: remove ? We pass to mobile interface before reaching this scenario...
    dropdown('d-sm-none') do
      children.each do |child|
        Toolbar::Dropdown::Item(convert_params(child))
      end
    end

  end

  def dropdown(class_name = 'd-inline align-self-center')
    DIV(class: "dropdown #{class_name}") do
      Toolbar::Button(text: '', icon: 'ellipsis-h', toggle: 'dropdown', variant: variant)
      DIV(class: 'dropdown-menu dropdown-menu-right') do
        yield
      end
    end
  end

  def convert_params(child)
    props = Hash.new(`#{child.to_n}.props`)

    params = {
      target: props[:target],
      icon: props[:icon],
      text: props[:text],
      className: props[:className],
      disabled: props[:disabled],
    }

    params['data-toggle'] = props[:toggle] if props[:toggle]
    params['data-dismiss'] = props[:dismiss] if props[:dismiss]
    params[:onClick] = props[:onClick] if props[:onClick]

    return params
  end

end
