class Layout
  class Editor
    module Panel
      module Layout
        module Column
          class Base < Panel::Base

            collect_other_params_as :other_params

            render { content }

            def parameters
              label_parameter
              col_size_parameter
            end

            def col_size_parameter
              ::Form::Element::Attribute::Enum(
                attribute_name: 'col_width',
                label: I18n.t('activerecord.attributes.dynamic/chart/base.width'),
                possible_values: [
                  {label: "8% #{I18n.t('layout_editor.parents_size').downcase}", value: 'col-1'},
                  {label: "17% #{I18n.t('layout_editor.parents_size').downcase}", value: 'col-2'},
                  {label: "25% #{I18n.t('layout_editor.parents_size').downcase}", value: 'col-3'},
                  {label: "30% #{I18n.t('layout_editor.parents_size').downcase}", value: 'col-4'},
                  {label: "42% #{I18n.t('layout_editor.parents_size').downcase}", value: 'col-5'},
                  {label: "50% #{I18n.t('layout_editor.parents_size').downcase}", value: 'col-6'},
                  {label: "58% #{I18n.t('layout_editor.parents_size').downcase}", value: 'col-7'},
                  {label: "70% #{I18n.t('layout_editor.parents_size').downcase}", value: 'col-8'},
                  {label: "75% #{I18n.t('layout_editor.parents_size').downcase}", value: 'col-9'},
                  {label: "80% #{I18n.t('layout_editor.parents_size').downcase}", value: 'col-10'},
                  {label: "90% #{I18n.t('layout_editor.parents_size').downcase}", value: 'col-11'},
                  {label: "100% #{I18n.t('layout_editor.parents_size').downcase}", value: 'col'},
                ],
                accept_empty_value: false,
                default_value: 'col',
              )
            end

          end
        end
      end
    end
  end
end
