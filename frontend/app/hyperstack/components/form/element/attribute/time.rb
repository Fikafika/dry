require 'components/form/element/attribute/date_time'

class Form
  module Element
    module Attribute

      class Time < ::Form::Element::Attribute::String
        render { content }

        def input_args
          r = super
          r[:type] = 'time'
          r[:step] = 1
          return r
        end

      end

    end
  end
end
