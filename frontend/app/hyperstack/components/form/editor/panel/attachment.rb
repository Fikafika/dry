class Form
  class Editor
    module Panel
      module Attachment
        class Base < Panel::Base
          render { content }

          def parameters
            label_parameter
            requirement_parameter
            help_parameter
            watermark_parameter
            editor_parameter
            errors_from_parameter
            css_classes_parameter
            column_layout_parameters
            parent_settings_parameters
            disabled_parameter
          end

        end
      end
    end
  end
end
