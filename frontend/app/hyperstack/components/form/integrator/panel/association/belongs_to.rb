class Form
  class Integrator
    module Panel
      module Association
        class BelongsTo < Association::Base
          render { content }

          def parameters
            Form::Element::Association::BelongsTo(
              attribute_name: "default_params_#{element.attribute_name}",
              target_klass: target_klass_assoc,
              polymorphic: true,
              target_klass_url: target_klass_url,
              label: label
            )
          end

          def target_klass_assoc
            return record.klass.reflect_on_association(element.attribute_name).klass
          end

        end
      end
    end
  end
end
