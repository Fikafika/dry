class Form
  class Editor
    module Panel
      module Attribute
        class Boolean < Panel::Attribute::Base
          render { content }

          def label_parameter
            ::Form::Element::Attribute::TranslatableString(
              {
                attribute_name: 'label',
                nullify: true,
              }.merge!(
                placeholders do
                  record.klass&.human_attribute_name(record.attribute_name)&.capitalize
                end
              )
            )
            ::Form::Element::Layout::Condition(proc: Proc.new{|r| r.editor.present?}) do
              ::Form::Element::Attribute::Boolean(attribute_name: 'show_label', default_value: true)
            end
          end

          def column_layout_parameters
            return super if mode != 'input'
            ::Form::Element::Layout::Condition(proc: Proc.new{|r| r.editor.present?}) do
              super
            end
            ::Form::Element::Layout::Condition(proc: Proc.new{|r| r.editor.blank?}) do
              ::Form::Element::Layout::Accordion(
                title: I18n.t('activerecord.values.dynamic/form/element/base.section.column_layout.title'),
                style: accordion_style,
                is_last: true,
              ) do
                ::Form::Element::Attribute::Enum(
                  attribute_name: 'label_col_size',
                  label: I18n.t('activerecord.values.dynamic/form/element/base.section.column_layout.offset_width'),
                  possible_values: col_size_options,
                  default_value: 'col-md-3',
                )
              end
            end
          end
        end
      end
    end
  end
end
