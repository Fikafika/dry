class Layout
  class Editor
    module Panel
      module DIV
        class Base < Panel::Base

          collect_other_params_as :other_params

          render { content }

          def parameters
            class_parameter
          end

          def class_parameter
            ::Form::Element::Attribute::String(attribute_name: 'class')
          end

        end
      end
    end
  end
end
