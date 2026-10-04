class Layout
  class Editor
    module Panel
      module Crm
        module TransactionLine
          module Table
            class Base < ::Layout::Editor::Panel::Crm::Sheet::Table::Base

              def schema_association_klass_id
                element.component_params['schema_association_id']
              end

              def schema_association_ids_parameter
                ::Form::Element::Attribute::Enum(
                  attribute_name: 'schema_association_id',
                  possible_values: possible_values_association,
                ).on(:change) do |value|
                  after(0.1) do
                    mutate
                  end
                end
              end

            end
          end
        end
      end
    end
  end
end
