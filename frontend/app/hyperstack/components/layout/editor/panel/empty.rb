class Layout
  class Editor
    module Panel
      module Empty
        class Base < Panel::Base

          collect_other_params_as :other_params

          render {}
        end
      end
    end
  end
end
