class Layout
  class Editor
    module Panel
      module Toolbar
        class Base < Panel::Base

          collect_other_params_as :other_params

          render { content }

          def parameters
            css_class_parameter
          end

        end
      end
    end
  end
end
