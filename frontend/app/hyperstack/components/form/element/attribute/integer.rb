require 'components/form/element/attribute/numeric'

class Form
  module Element
    module Attribute

      class Integer < ::Form::Element::Attribute::Numeric
        render { content }

        def input_args
          result = super.merge!({
            type: 'number',
            step: 1
          })
          result[:min] = other_params[:min] if other_params[:min]
          result[:max] = other_params[:max] if other_params[:max]
          result
        end

        private

        def rounded_shift(v, scale)
          super.round
        end

      end

    end
  end
end
