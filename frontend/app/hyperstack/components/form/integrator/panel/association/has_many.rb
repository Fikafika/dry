class Form
  class Integrator
    module Panel
      module Association
        class HasMany < Association::Base
          render { content }

          def parameters
            Form::Element::Association::HasMany(
              attribute_name: "default_params_#{element.attribute_name}",
              target_klass: target_klass_assoc,
              polymorphic: true,
              target_klass_url: target_klass_url,
              label: label
            )
          end
        end
      end
    end
  end
end
