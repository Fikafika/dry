class Form
  class Integrator
    module Panel
      class ParamsSection < HyperComponent
        param :additional_params

        fires :changed

        render do
          DIV do
            DIV do
              LABEL { I18n.t("crm.form_integrator.additional_params.label")}
            end
            DIV do
              DIV(class: 'form-group') do
                additional_params.each_with_index do |param, index|
                  DIV(class: 'd-flex mb-2 align-items-center', key: "param-row-#{index}") do
                    DIV(class: 'mr-2 col-md-6') { param[:name] }
                    DIV(class: 'mr-2 col-md-6') { param[:value] }
                  end
                end
                DIV(class: 'text-center mt-3') do
                  BUTTON(
                    type: 'button',
                    class: 'btn btn-sm btn-outline-primary'
                  ) do
                    I(class: 'fa fa-plus mr-1')
                    SPAN { I18n.t("crm.form_integrator.additional_params.button") }
                  end.on(:click) do |e|
                    e.prevent_default
                    changed!
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
