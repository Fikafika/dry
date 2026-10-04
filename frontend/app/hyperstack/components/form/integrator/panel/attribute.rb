class Form
  class Integrator
    module Panel
      module Attribute
        class Base < Panel::Base
          render { content }

          def parameters
            default_value_parameter
          end

          def default_value_parameter
            ::Form::Element::Attribute::String(attribute_name: "default_params_#{element.attribute_name}", label: label)
          end

        end

        class Boolean < Base; end
        class Date < Base
          def default_value_parameter
            ::Form::Element::Attribute::Date(attribute_name: "default_params_#{element.attribute_name}", label: label)
          end
        end
        class DateTime < Base
          def default_value_parameter
            ::Form::Element::Attribute::DateTime(attribute_name: "default_params_#{element.attribute_name}", label: label)
          end
        end
        class Integer < Base
          def default_value_parameter
            ::Form::Element::Attribute::Integer(attribute_name: "default_params_#{element.attribute_name}", label: label)
          end
        end
        class String < Base; end
        class Text < Base; end
        class TimeOfDay < Base; end
        class Float < Base
          def default_value_parameter
            ::Form::Element::Attribute::Float(attribute_name: "default_params_#{element.attribute_name}", label: label)
          end
        end
        class Enum < Base
          render { content }
          def default_value_parameter
            ::Form::Element::Attribute::Enum(attribute_name: "default_params_#{element.attribute_name}", possible_values: possible_values, label: label)
          end

          def possible_values
            record.klass.attributes.dig(record.attribute_name, 'possible_values', I18n.locale)
          end

        end

      end
    end
  end
end
