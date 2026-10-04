class Settings
  class Schema
    class Forms
      class Editor < HyperComponent

        render do
          ::Form::Editor(
            klass_id: request.params['klass_id'],
            schema_id: request.params['schema_id'],
            form_id: request.params['form_id'],
            return_back_button_on_click: Proc.new do
              App.history.push(request.location.pathname.gsub(/\/edit$/, ''))
            end
          )
        end

      end
    end
  end
end
