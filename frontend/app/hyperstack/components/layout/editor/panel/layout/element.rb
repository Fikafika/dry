class Layout
  class Editor
    module Panel
      module Layout
        module Element
          class Base < Panel::Base

            collect_other_params_as :other_params

            render { content }

            def parameters
              label_parameter
            end

          end
        end
      end
    end
  end
end
