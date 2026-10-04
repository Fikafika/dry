require 'components/form/element/base'

class Form
  module Element
    module Control
      class Base < ::Form::Element::Base

        render { content }

      end
    end
  end
end
