class ContextMenu < HyperComponent

  param :position, default: nil
  param :z_index, default: 100000
  param :css_position, default: "absolute"

  fires :hidden

  after_mount do
    if position
      show
    end
  end

  after_update do
    if position
      show
    end
  end

  render do
    next unless position
    DIV(class: 'dropdown-menu context-menu', style: {position: css_position}) do
      children.render
    end
  end

  def show
    self.jq_node.css(top: "#{position[:y]}px", left: "#{position[:x]}px", 'z-index': z_index).show()
    ::Element['body'].off('click.dynamo.context_menu').on('click.dynamo.context_menu') do |event| # beurk
      ::Element['.context-menu'].hide()
      after(0.1) do
        hidden!
      end
    end
  end
end
