require 'components/layout/element'

class Layout::Row < ::Layout::Element

  render { content }

  def content
    DIV(class: "row #{other_params[:row_height]} #{other_params[:className] ? ' ' + other_params[:className] : nil} #{other_params[:row_min_height]}") do
      super { children.render }
    end
  end

end
