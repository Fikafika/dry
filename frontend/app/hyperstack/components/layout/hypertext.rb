require 'components/layout/element'

class Layout::Hypertext < ::Layout::Element

  render { content }

  def content
    DIV do
      A(href: other_params[:url_target]){ other_params[:text]}
    end
    DIV do
      super { children.render }
    end
  end
end