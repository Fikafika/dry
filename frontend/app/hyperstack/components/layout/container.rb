require 'components/layout/element'

class Layout::Container < ::Layout::Element
  render { content }

  def content
    DIV(class: "container-fluid #{other_params[:container_height]}") do
      super { children.render }
    end
  end

end
