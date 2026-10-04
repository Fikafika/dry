class Form
  class Integrator
    module Panel
      class Empty < Panel::Base

        render {content}

        def render_element_specific_section
        end

        def title
          DIV(class: 'border-bottom mb-3') do
            DIV { I18n.t("crm.form_integrator.heading_params") }
          end
        end

      end
    end
  end
end
