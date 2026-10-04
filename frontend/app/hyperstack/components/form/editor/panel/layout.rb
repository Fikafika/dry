class Form
  class Editor
    module Panel
      module Layout
        class Base < Panel::Base
          render { content }

          def parameters
          end

          def title_path
            record.class.model_name.human
          end
        end

        class Condition < Base
          render { content }

          def parameters
            label_parameter
            condition_parameter
          end

          def label_parameter
            ::Form::Element::Attribute::TranslatableString(
              {
                attribute_name: 'label',
                nullify: true,
                #help: "(affiché dans l'éditeur)"
              }
            )
          end

          def condition_parameter
            ConditionFormula(key: "condition-#{record.id}", attribute_name: 'condition_formula', get_elements_path: get_elements_path, get_variable: get_variable, klass: record.klass_name&.safe_constantize)
          end

          def get_elements_path
            Proc.new do |set_klasses|
              other_params[:enableInspectMode].call(
                Proc.new do |inspected_element|
                  attrs = Hash.new(inspected_element)
                  unless attrs[:type] == 'Layout::Condition'
                    r = (attrs[:method_names].to_a + [attrs[:attribute_name]]).join('.')
                    set_klasses.call(
                      target_klass_of(attrs)
                    )
                  end
                end.to_n
              )
            end
          end

          def target_klass_of(el)
            dy_element = ::Dynamic::Form::Element::Base.polymorphic_new(el)
            r = (dy_element.method_names.to_a + [dy_element.attribute_name]).join('.')

            return {
              root_klass: dy_element.root_klass,
              klass: dy_element.klass.reflect_on_association(el[:attribute_name])&.klass || dy_element.klass,
              path_name: r
            }
          end

          def get_variable
            @get_variable ||= Proc.new do |result|
              other_params[:enableInspectMode].call(
                Proc.new do |element|
                  attrs = Hash.new(element)
                  r = (attrs[:method_names].to_a + [attrs[:attribute_name]]).join('.')
                  result.call(r)
                end.to_n
              )
            end
          end
        end

        class Container < Base; end

        class Page < Base

          render { content }

          def parameters
            label_parameter
          end

          def label_parameter
            ::Form::Element::Attribute::TranslatableString(
              {
                attribute_name: 'label',
                nullify: true,
                #help: "(affiché dans l'éditeur)"
              }
            )
          end
        end
        class Row < Base; end
        class Column < Base; end

      end
    end
  end
end
