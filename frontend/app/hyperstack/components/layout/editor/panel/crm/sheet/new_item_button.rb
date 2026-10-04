class Layout
  class Editor
    module Panel
      module Crm
        module Sheet
          module NewItemButton
            class Base  < Panel::Base

              def params_converter_parameters
                ::Form::Element::Attribute::Hash(
                  attribute_name: 'component_params_converter_options',
                  mode: 'nested_form'
                ) do
                  translated_parameter(
                    attribute_name: 'text',
                    label: I18n.t("layout_editor.panel.new_item_button.text")
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
