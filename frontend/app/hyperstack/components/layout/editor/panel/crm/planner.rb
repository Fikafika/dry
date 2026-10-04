class Layout
  class Editor
    module Panel
      module Crm
        module Planner
          class Base < Panel::Base
            include Layout::Editor::Panel::Base::Associations

            collect_other_params_as :other_params

            render { content }

            def params_converter_parameters
              ::Form::Element::Attribute::Hash(
                attribute_name: 'component_params_converter_options',
                mode: 'nested_form'
              ) do
                resource_parameters
              end
            end

            def resource_parameters
              H6{ I18n.t('crm.planner.layout_editor.label_default_resource') }
              Form::Element::Attribute::MultipleEnum(
                attribute_name: 'resources',
                possible_values: possible_resources
              )
            end

            def layout
              element.try(:layout)
            end

            def klass_name
              layout&.klass_name
            end

            def klass
              klass_name&.safe_constantize
            end

            def possible_resources
              return @possible_resources unless @possible_resources.nil?

              resource_list = possible_associations.dup

              schema_klass.attrs.each do |attr|
                next unless attr.type == 'Enum'

                resource_list << {
                  value: attr.id,
                  label: attr.human_name
                }
              end

              @possible_resources = resource_list
            end
          end
        end
      end
    end
  end
end
