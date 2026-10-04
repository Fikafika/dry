class Layout
  class Editor
    module Panel
      module Layout
        module Hypertext
          class Base < Panel::Base

            collect_other_params_as :other_params

            render { content }

            def parameters
              text_parameter
              url_parameter
            end

            def text_parameter
              ::Form::Element::Attribute::String(attribute_name: 'text')
            end

            def url_parameter
              ::Form::Element::Attribute::String(attribute_name: 'url_target')
            end
          end
        end
      end
    end
  end
end
