class Layout
  class Editor
    module Panel
      module Layout
        module Container
          class Base < Panel::Base

            collect_other_params_as :other_params

            render { content }

            def parameters
              label_parameter
              container_height_parameter
            end

            def container_height_parameter
              ::Form::Element::Attribute::Enum(
                attribute_name: 'container_height',
                label: I18n.t('activerecord.attributes.dynamic/chart/base.height'),
                possible_values: [
                  {label: 'Flexible', value: ''},
                  {label: '25% container', value: 'h-25'},
                  {label: '50% container', value: 'h-50'},
                  {label: '75% container', value: 'h-75'},
                  {label: '100% container', value: 'h-100'},
                ],
                accept_empty_value: false,
                default_value: '',
              )
            end
          end
        end
      end
    end
  end
end
