require 'components/form/element/attribute/string'

class Form
  module Element
    module Attribute

      class Icon < ::Form::Element::Attribute::String

        param :placeholder_icon, default: 'square far'

        render { content }

        def render_input
          layout_input do
            icon_btn
            icon_hidden_input
            input_errors
          end
        end

        def icon_btn
          A(
            href: '#',
            class: "icon-selector-button btn btn-lg input-group-text fa fa-#{form.submission.read(path) || placeholder_icon} fa-2x",
            'data-nameless': true,
          ) do
            value
          end.on(:click) do |event|
            event.prevent_default
          end
        end

        def icon_hidden_input
          INPUT(input_args.merge(type: 'hidden', class: 'icon-selector-input'))
          ::Document.off(:change, "##{input_id}").on(:change, "##{input_id}") do |event|
            change_value(event.target.value)
          end
        end

        before_unmount do
          ::Element.find('.popover').remove
        end


      end

    end
  end
end
