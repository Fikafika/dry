require 'components/form/element/layout/base'
require 'components/accordion'

class Form
  module Element
    module Layout
      class Accordion < ::Form::Element::Layout::Base

        param :title, default: nil
        param :is_open, default: false
        param :style, default: nil
        param :is_last, default: false

        render { content }

        def content
          Hyperstack::Internal::Component::RenderingContext.render(
            ::Accordion,
            title: title,
            is_open: is_open,
            style: style,
            is_last: is_last,
          ) do
            children_render
          end
        end
      end
    end
  end
end