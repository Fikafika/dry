class Form
  class Editor
    module Panel
      module Control
        class Base < Panel::Base
          render { content }

          def parameters
          end
        end

        class AddButton < Base
          render { content }

          def parameters
            text_parameter
          end

          def text_parameter
            ::Form::Element::Attribute::TranslatableString({
              attribute_name: 'text',
              nullify: true,
            }.merge!(
                placeholders do
                  I18n.t('shared.add')
                end
              )
            )
          end

          def human_attribute_name
            record.class.model_name.human
          end

          def human_path(klass, path)
            return [] unless klass && path.any?
            result = super(klass, path[0..-2])
            result << record.class.model_name.human
            return result
          end

        end

        class Print < Base
          render { content }

          def title_path
            record.class.model_name.human
          end
        end

        class Navigation < Base
          render { content }

          def parameters
            ['previous', 'next', 'cancel', 'save_as_draft', 'submit'].each do |btn|
              button_parameters(btn)
            end
          end

          def button_parameters(btn)
            DIV(class: 'pb-2') do
              I18n.t("crm.form_editor.#{btn}_button")
            end
            ::Form::Element::Attribute::TranslatableString(
              {
                attribute_name: "#{btn}_button_text",
                label: I18n.t('crm.form_editor.text'),
                nullify: true,
              }.merge!(
                placeholders do
                  I18n.t("form.#{btn}")
                end
              )
            )
            ::Form::Element::Attribute::Boolean(
              {
                attribute_name: "show_#{btn}_button",
                label: I18n.t('crm.form_editor.show_button')
              }
            )
            HR(){}
          end

          def title_path
            record.class.model_name.human
          end
        end

      end
    end
  end
end
