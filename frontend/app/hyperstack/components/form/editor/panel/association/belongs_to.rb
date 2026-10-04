class Form
  class Editor
    module Panel
      module Association
        class BelongsTo < Association::Base
          render { content }

          def min_max_parameters # redefined
            ::Form::Element::Layout::Condition(mode: 'nested_form') do
              ::Form::Element::Attribute::Integer(attribute_name: 'min')
            end
          end

          def default_value_parameter
            Form::Element::Association::BelongsTo(
              attribute_name: 'default_value_record',
              target_klass: target_klass,
              target_klass_url: target_klass_url,
              polymorphic: true,
            )
            Form::Element::Attribute::String(attribute_name: 'default_value_formula', target_klass: target_klass)
            Form::Element::Attribute::Enum(attribute_name: 'record_type_for_default_value_formula')
            Form::Element::Attribute::Boolean(attribute_name: 'force_default_value', default_value: false)
          end

        end
      end
    end
  end
end
