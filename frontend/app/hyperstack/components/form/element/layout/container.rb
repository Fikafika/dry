require 'components/form/element/layout/base'

class Form
  module Element
    module Layout
      class Container < ::Form::Element::Layout::Base

        render { content }

        def content
          DIV(ref: _ref, class: 'container-fluid') do
            children_render
          end
        end

      end
    end
  end
end
