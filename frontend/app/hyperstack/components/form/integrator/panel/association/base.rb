class Form
  class Integrator
    module Panel
      module Association
        class Base < Panel::Base
          render { content }

          def target_klass_assoc
            return record.klass.reflect_on_association(record.attribute_name)&.klass
          end

          def target_klass_url
            if target_klass_assoc
              target_klass_assoc.collection_path
            elsif record.klass && record.klass.parent.respond_to?(:search_path)
              record.klass.parent.search_path(klass_names: record.target_klass_names)
            end
          end

        end
      end
    end
  end
end