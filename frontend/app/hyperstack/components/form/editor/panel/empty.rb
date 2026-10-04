class Form
  class Editor
    module Panel
      class Empty < HyperComponent

        collect_other_params_as :other_params

        render do
          ''
        end
      end
    end
  end
end
