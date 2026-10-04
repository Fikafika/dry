class Form
  class Editor
    module Panel
      module Attribute
        class Base < Panel::Base
          render { content }

          def parameters
            label_parameter
            requirement_parameter
            help_parameter
            watermark_parameter
            editor_parameter
            ::Form::Element::Layout::Accordion(
              title: I18n.t('activerecord.values.dynamic/form/element/base.section.default_value'),
              style: accordion_style
            ) do
              default_value_parameter
            end
            css_classes_parameter
            column_layout_parameters
            parent_settings_parameters
            errors_from_parameter
            disabled_parameter
          end

          def default_value_parameter
            default_value_parameter_from_element_klass
          end
        end

        class Boolean < Base; end
        class Date < Base; end
        class DateTime < Base; end
        class Float < Base; end
        class Integer < Base; end
        class String < Base; end
        class Text < Base; end
        class TimeOfDay < Base; end
        class TranslatableString < Base
          def default_value_parameter
            ::Form::Element::Attribute::TranslatableString(attribute_name: 'translated_default_value')
            ::Form::Element::Attribute::Boolean(attribute_name: 'force_default_value', default_value: false)
          end
        end
        class TranslatableText < Base
          def default_value_parameter
            ::Form::Element::Attribute::TranslatableText(attribute_name: 'translated_default_value')
            ::Form::Element::Attribute::Boolean(attribute_name: 'force_default_value', default_value: false)
          end
        end

        class Enum < Base
          render { content }

          def parameters
            label_parameter
            requirement_parameter
            help_parameter
            if [nil, 'select'].include?(record.editor)
              watermark_parameter
            end
            editor_parameter
            if ['radio', 'radio_inline'].include?(record.editor)
              value_position_parameter
              show_value_parameter
            end
            ::Form::Element::Layout::Accordion(
              title: I18n.t('activerecord.values.dynamic/form/element/base.section.possible_value'),
              style: accordion_style
            ) do
              possible_values_parameter
            end
            ::Form::Element::Layout::Accordion(
              title: I18n.t('activerecord.values.dynamic/form/element/base.section.default_value'),
              style: accordion_style
            ) do
              default_value_parameter
            end
            css_classes_parameter
            column_layout_parameters
            parent_settings_parameters
            disabled_parameter
          end

          def default_value_parameter
            ::Form::Element::Attribute::Enum(attribute_name: 'default_value', possible_values: possible_values)
            ::Form::Element::Attribute::String(attribute_name: 'default_value_formula', target_klass: record.klass)
            ::Form::Element::Attribute::Enum(attribute_name: 'record_type_for_default_value_formula')
            ::Form::Element::Attribute::Boolean(attribute_name: 'force_default_value', default_value: false)
          end

          def possible_values_parameter
            Form::Element::Association::HasMany(attribute_name: 'possible_values', mode: 'nested_form') do
              Form::Element::Attribute::TranslatableString(attribute_name: 'text')
              Form::Element::Attribute::Enum(attribute_name: 'value', possible_values: possible_values)
            end
            Form::Element::Control::AddButton(attribute_name: 'possible_values')
          end

          def possible_values
            record.klass.attributes.dig(record.attribute_name, 'possible_values', I18n.locale)
          end

        end

      end
    end
  end
end
