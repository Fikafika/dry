require 'components/form/element/layout/base'

class Form
  module Element
    module Layout
      class Row < ::Form::Element::Layout::Base

        render { content }

        def content
          DIV(ref: _ref, class: 'row') do
            children_render
          end
        end

      end
    end
  end
end
