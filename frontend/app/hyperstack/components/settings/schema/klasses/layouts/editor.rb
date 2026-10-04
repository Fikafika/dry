class Settings
  class Schema
    class Layouts
      class Editor < HyperComponent

        render do
          ::Layout::Editor(
            klass_id: request.params['klass_id'],
            schema_id: request.params['schema_id'],
            layout_id: request.params['layout_id'],
            return_back_button_on_click: Proc.new do
              App.history.push(request.location.pathname.gsub(/\/edit$/, ''))
            end
          )
        end

      end
    end
  end
end
