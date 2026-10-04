class Layout
  class Editor
    module Panel
      module Layout
        module Row
          class Base < Panel::Base

            collect_other_params_as :other_params

            render { content }

            def parameters
              label_parameter
              row_height_parameter
            end

            def row_height_parameter
              ::Form::Element::Attribute::Enum(
                attribute_name: 'row_min_height',
                label: I18n.t('activerecord.attributes.dynamic/chart/base.min_height'),
                possible_values: [
                  {label: I18n.t('activerecord.attributes.dynamic/chart/base.no_min_height'), value: ''},
                  {label: '100px', value: 'row-min-height-100px'},
                  {label: '200px', value: 'row-min-height-200px'},
                  {label: '300px', value: 'row-min-height-300px'},
                  {label: '400px', value: 'row-min-height-400px'},
                  {label: '500px', value: 'row-min-height-500px'},
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
