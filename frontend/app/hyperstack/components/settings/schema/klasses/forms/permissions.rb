class Settings
  class Schema
    class Forms
      class Permissions < Base

        def klass_name
          'Dynamic::Form'
        end

        def rules
          observe @rules = ::UneekPermission::Rule.where(
            klass_name: klass_name,
            instance_id: form_id,
            schema_id: schema.id,
          ).all
        end

        def list_page
          Stackable::LargePage() do
            Stackable::Toolbar() do
              Stackable::PageHeader(title: ::UneekPermission::Rule.model_name.human, back: back_location)
            end
            ::Permission::Manager(
              rules: rules,
              params_for_new_record: {
                klass_name: klass_name,
                instance_id: form_id,
                attr: nil,
              },
              on_instance: true,
            )
          end
        end

      end
    end
  end
end
