class Layout
  class Editor
    module Panel
      module Crm
        module Sheet
          module Table
            class Base < Panel::Base

              collect_other_params_as :other_params

              render { content }

              def parameters
                schema_association_ids_parameter
                nowrap_parameter
                table_columns_parameter
              end

              def klass_name
                other_params[:layout]&.klass_name.split('::')[-1]
              end

              def klass
                other_params['schema'].klasses.each do |k|
                  if k.name == klass_name
                    return k
                  end
                end
              end

              def schema_association_klass
                association_id = schema_association_id
                return unless (association_id != "") && !association_id.nil?
                schema_association_klass_id = nil
                all_associations.each do |a|
                  if a.id == association_id
                    schema_association_klass_id = a.target_klass_id
                  end
                end
                other_params['schema'].klasses.each do |k|
                  if k.id == schema_association_klass_id
                    return k
                  end
                end
              end

              def schema_association_id
                element.component_params['schema_association']
              end

              def possible_value_table_columns
                possible_values = []
                schema_association_klass&.attrs&.each do |attr|
                  possible_values << {"value": attr.name, "label": attr.name}
                end
                return possible_values
              end

              def all_associations
                klass.associations
              end

              def possible_values_association
                possible_values = []
                all_associations.each do |a|
                  if a.type == "HasMany"
                    possible_values << {"value": a.id, "label": a.human_name}
                  end
                end
                return possible_values
              end

              def schema_association_ids_parameter
                ::Form::Element::Attribute::Enum(
                  attribute_name: 'schema_association',
                  possible_values: possible_values_association,
                ).on(:change) do |value|
                  after(0.1) do
                    mutate
                  end
                end
              end

              def nowrap_parameter
                Form::Element::Attribute::Boolean(attribute_name: 'nowrap', default_value: false)
              end

              def table_columns_parameter
                # TODO this doesn't work because it is not an association
                # it is an array of hash
                Form::Element::Association::HasMany(attribute_name: 'table_columns', mode: 'nested_form') do
                  Form::Element::Attribute::String(attribute_name: 'name', show_label: true)
                  Form::Element::Attribute::Enum(attribute_name: 'column', possible_values: possible_value_table_columns, show_label: true)
                end
                Form::Element::Control::AddButton(attribute_name: 'table_columns')
              end

            end
          end
        end
      end
    end
  end
end
