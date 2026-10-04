class Layout
  class Editor
    module Panel
      module Forms
        module Footer
          class Base < Panel::Base

            collect_other_params_as :other_params

            render { content }

            def parameters
            end

          end
        end
      end
    end
  end
end
