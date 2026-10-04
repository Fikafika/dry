require 'components/form/element/attribute/numeric'

class Form
  module Element
    module Attribute

      class Float < ::Form::Element::Attribute::Numeric
        render { content }

        def input_args
          super.merge!({
            type: 'number',
            step: scaled? ? 'any' : (other_params[:step] || 0.01),
          })
        end

      end

    end
  end
end
