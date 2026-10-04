class Layout
  class Editor
    module Panel
      module Layout
        module Title
          class Base < Panel::Base

            collect_other_params_as :other_params

            render { content }

            def parameters
              title_parameter
              position_parameter
              italic_parameter
              bold_parameter
              color_parameter
            end

            def title_parameter
              ::Form::Element::Attribute::String(attribute_name: 'title')
            end

            def position_parameter
              ::Form::Element::Attribute::Enum(
                attribute_name: 'position',
                possible_values: [
                  {label: I18n.t('layout_editor.left'), value: 'left'},
                  {label: I18n.t('layout_editor.center'), value: 'center'},
                  {label: I18n.t('layout_editor.right'), value: 'right'},
                ],
                accept_empty_value: false,
                default_value: 'left',
              )
            end

            def italic_parameter
              ::Form::Element::Attribute::Boolean(attribute_name: 'italic', default_value: false)
            end

            def bold_parameter
              ::Form::Element::Attribute::Boolean(attribute_name: 'bold', default_value: false)
            end

            def color_parameter
              ::Form::Element::Attribute::String(attribute_name: 'color', default_value: 'dark')
            end

          end
        end
      end
    end
  end
end
