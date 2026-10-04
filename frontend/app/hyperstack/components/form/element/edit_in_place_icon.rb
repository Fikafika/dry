class Form
  module Element
    class EditInPlaceIcon < HyperComponent
      param :success
      param :loading
      param :style
      param :error_message

      render do
        css_class = 'position-absolute mr-3 mt-2 fas cursor-pointer'
        if loading
          I(class: "#{css_class} fa-spinner", style: style, 'data-html': true)
        elsif success == true
          I(class: "#{css_class} fa-check text-success", style: style, 'data-html': true)
        elsif success == false
          if error_message.present?
            I(class: "#{css_class} fa-times text-danger", style: style, 'data-html': true, 'data-content': error_message, 'data-toggle': 'popover')
          else
            I(class: "#{css_class} fa-times text-danger", style: style, 'data-html': true)
          end
        else
          I(class: "#{css_class} fa-pencil-alt edit-icon", style: style, 'data-html': true)
        end
      end

      after_render do
        if success == false
          if error_message
            @was_shown = true
            self.jq_node.popover('show')
          end
        elsif @was_shown
          self.jq_node.popover('hide')
        end
      end

      before_unmount do
        self.jq_node.popover('dispose')
      end
    end
  end
end
