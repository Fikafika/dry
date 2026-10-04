require 'components/form/element/base'

class Form
  module Element
    class Honeypot < Base

      render { content }

      def content
        html_id = "#{attribute_name}_#{::Honeypot.honeypot_string}_#{Time.current.to_i + rand(999)}".gsub(/\]\[|[^-a-zA-Z0-9:.]/, "_")
        DIV(id: html_id) do
          STYLE(type: 'text/css', media: 'screen') do
            %Q([id='#{html_id}'] { display: none; })
          end
          layout_input do
            (rand(2) == 0 ? INPUT(input_args.merge(type: 'text')) : TEXTAREA(input_args)).on(:input) do |event|
              change_value(event.target.value)
            end
          end
        end
      end

      def path
        [attribute_name]
      end

      def label
        I18n.t('form.honeypot')
      end

    private

      def input_args
        {
          id: input_id,
          name: attribute_name,
          type: 'text',
          class: "form-control #{invalid_css_class} #{input_class}",
        }
      end

    end
  end
end
