require 'components/form/element/base'

class Form
  class Editor
    module Panel
      module Layout
        class Section < ::Form::Editor::Panel::Base

          def parameters
            section_title_parameter
            ::Form::Element::Attribute::Hash(
              attribute_name: 'css_classes',
              mode: 'nested_form',
            ) do
              section_title_tag_parameter
              section_color_parameter
              section_behavior_parameter
              section_appearance_parameter
              section_margin_parameter
              css_classes_parameter
            end
          end

          def section_title_parameter
            ::Form::Element::Attribute::TranslatableString(
              attribute_name: 'label',
              label: I18n.t('activerecord.attributes.dynamic/form/element/layout/section.title'),
              nullify: true
            )
          end

          def section_title_tag_parameter
            ::Form::Element::Attribute::Enum(
              attribute_name: 'font_size',
              label: I18n.t('activerecord.attributes.dynamic/form/element/layout/section.title_tag'),
              possible_values: [
                { value: 'h1', label: 'H1' },
                { value: 'h2', label: 'H2' },
                { value: 'h3', label: 'H3' },
                { value: 'h4', label: 'H4' },
                { value: 'h5', label: 'H5' },
                { value: 'h6', label: 'H6' }
              ]
            )
          end

          def section_color_parameter
            ::Form::Element::Attribute::Enum(
              attribute_name: 'color',
              possible_values: [
                { value: 'bg-primary text-white', label: "Primary" },
                { value: 'bg-secondary text-white', label: "Secondary" },
                { value: 'bg-success text-white', label: "Success" },
                { value: 'bg-info text-white', label: "Info"},
                { value: 'bg-warning text-dark', label: "Warning" },
                { value: 'bg-danger text-white', label: "Danger" },
                { value: 'bg-dark text-white', label: "Dark" },
                { value: 'bg-light text-dark', label: "Light" },
                { value: 'bg-white text-dark', label: "White" }
              ],
              default_value: 'default'
            )
          end

          def section_behavior_parameter
            ::Form::Element::Layout::Accordion(
              title: I18n.t('activerecord.attributes.dynamic/form/element/layout/section.behavior_title'),
              style: accordion_style
            ) do
              ::Form::Element::Attribute::Enum(
                attribute_name: 'collapsible',
                help: I18n.t('activerecord.attributes.dynamic/form/element/layout/section.collapsible_help'),
                possible_values: [
                  { value: 'collapsible', label: I18n.t('shared._yes') },
                  { value: 'not-collapsible', label: I18n.t('shared._no') }
                ],
                default_value: nil
              )
            end
          end

          def section_appearance_parameter
            ::Form::Element::Layout::Accordion(
              title: I18n.t('activerecord.attributes.dynamic/form/element/layout/section.appearance_title'),
              style: accordion_style
            ) do
              ::Form::Element::Attribute::Enum(
                attribute_name: 'show_header',
                possible_values: [
                  { value: 'block', label: I18n.t('shared._yes') },
                  { value: 'd-none', label: I18n.t('shared._no') }
                ],
                default_value: nil
              )

              ::Form::Element::Attribute::Enum(
                attribute_name: 'show_border',
                possible_values: [
                  { value: 'border', label: I18n.t('shared._yes') },
                  { value: 'border-0', label: I18n.t('shared._no') }
                ],
                default_value: nil
              )


              Form::Element::Layout::Condition(
                show_border: 'border'
              ) do
                ::Form::Element::Attribute::Enum(
                  attribute_name: 'border_color',
                  possible_values: [
                    { value: 'border-primary', label: "Primary" },
                    { value: 'border-secondary', label: "Secondary" },
                    { value: 'border-success', label: "Success" },
                    { value: 'border-info', label: "Info"},
                    { value: 'border-warning', label: "Warning" },
                    { value: 'border-danger', label: "Danger" },
                    { value: 'border-light', label: "Light" },
                    { value: 'border-dark', label: "Dark" },
                    { value: 'border-white', label: "White" },
                  ],
                  default_value: nil
                )
              end

              ::Form::Element::Attribute::Enum(
                attribute_name: 'full_width',
                possible_values: [
                  { value: 'mx-n3', label: I18n.t('shared._yes') },
                  { value: 'auto', label: I18n.t('shared._no') }
                ],
                default_value: nil
              )
            end
          end

          def section_margin_parameter
            ::Form::Element::Layout::Accordion(
              title: I18n.t('activerecord.attributes.dynamic/form/element/layout/section.margin_title'),
              style: accordion_style
            ) do
              ::Form::Element::Attribute::Enum(
                attribute_name: 'margin_top',
                possible_values: margin_top_values,
                default_value: nil
              )

              ::Form::Element::Attribute::Enum(
                attribute_name: 'margin_bottom',
                possible_values: margin_bottom_values,
                default_value: nil
              )
            end
          end

          def css_classes_parameter
            ::Form::Element::Layout::Accordion(
              title: I18n.t('activerecord.attributes.dynamic/form/element/layout/section.css_classes_title'),
              style: accordion_style
            ) do
              ::Form::Element::Attribute::String(
                attribute_name: 'section',
                label: I18n.t('activerecord.attributes.dynamic/form/element/layout/section.section_class'),
              )

              ::Form::Element::Attribute::String(
                attribute_name: 'header',
                label: I18n.t('activerecord.attributes.dynamic/form/element/layout/section.header_class'),
              )

              ::Form::Element::Attribute::String(
                attribute_name: 'body',
                label: I18n.t('activerecord.attributes.dynamic/form/element/layout/section.body_class'),
              )
            end
          end

          private

          def margin_top_values
            margin_values_for('mt')
          end

          def margin_bottom_values
            margin_values_for('mb')
          end

          def margin_values_for(prefix)
            [
              { value: "#{prefix}-0", label: '0' },
              { value: "#{prefix}-1", label: '1 (0.25rem)' },
              { value: "#{prefix}-2", label: '2 (0.5rem)' },
              { value: "#{prefix}-3", label: '3 (1rem)' },
              { value: "#{prefix}-4", label: '4 (1.5rem)' },
              { value: "#{prefix}-5", label: '5 (3rem)' },
              { value: "#{prefix}-auto", label: 'Auto' }
            ]
          end

        end
      end
    end
  end
end