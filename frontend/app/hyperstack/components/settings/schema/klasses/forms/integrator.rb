class Settings
  class Schema
    class Forms
      class Integrator < HyperComponent

        render do
          ::Form::Integrator(
            klass_id: request.params['klass_id'],
            schema_id: request.params['schema_id'],
            form_id: request.params['form_id'],
            return_back_button_on_click: Proc.new do
              App.history.push(request.location.pathname.gsub(/\/integrate$/, ''))
            end
          )
        end

      end
    end
  end
end