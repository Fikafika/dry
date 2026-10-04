class Form
  class Editor
    module Panel
      module Basic
        class Base < Panel::Base
          render { content }

          def title_path
            record.class.model_name.human
          end

          def parameters
            text_parameter
            #attachments_parameter # TODO find a way to attach through tinymce
          end

          def text_parameter
            ::Form::Element::Attribute::TranslatableText(attribute_name: 'text', nullify: true, show_label: false, tinymce_inline: false)
          end

          def attachments_parameter
            ::Form::Element::Attachment::HasMany(attribute_name: 'attachments', serialize_value: true)
          end

        end
      end
    end
  end
end
