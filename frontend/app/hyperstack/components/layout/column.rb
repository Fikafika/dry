require 'components/layout/element'

class Layout::Column < ::Layout::Element

  render { content }

  def content
    DIV(class: "#{col_width}#{other_params[:className] ? ' ' + other_params[:className] : nil}") do
      super { children.render }
    end
  end

  def col_width
    other_params[:col_width] || 'col'
  end

end