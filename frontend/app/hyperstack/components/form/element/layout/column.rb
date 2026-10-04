require 'components/form/element/layout/base'

class Form
  module Element
    module Layout
      class Column < ::Form::Element::Layout::Base

        render { content }

        def content
          DIV(ref: _ref, class: col_classes) do
            children_render
          end
        end

        def col_classes
          [css_classes&.dig(:width) || col_size]
        end

        def col_size
          other_params[:col_size] || 'col'
        end

      end
    end
  end
end
