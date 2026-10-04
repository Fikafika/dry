class Layout
  class Editor
    module Panel
      module Toolbar
        module Dropdown
          module Item
            class Base < Panel::Base

              def params_converter_parameters
                ::Form::Element::Attribute::Hash(
                  attribute_name: 'component_params_converter_options',
                  mode: 'nested_form'
                ) do
                  translated_parameter(
                    attribute_name: 'text',
                  )
                end
              end

            end
          end
        end
      end
    end
  end
end
