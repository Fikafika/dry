require 'components/layout/element'

class Layout::Title < ::Layout::Element
  render { content }

  def content
    div_style = {
      textAlign: other_params[:position],
      fontStyle: other_params[:italic] ? 'italic' : '',
      fontWeight: other_params[:bold] ? 'bold' : '',
      color: other_params[:color],
    }
    H4(style: div_style) do
      other_params[:title]
    end
    DIV do
      super { children.render }
    end
  end

end
