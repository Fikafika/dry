class Settings
  class Schema
    module DocGen
      class Permissions < Base

        render { content }

        def klass
          schema.const::R::DocGen::Template
        end

        def rules
          observe @rules = ::UneekPermission::Rule.where(
            klass_name: klass.name,
            instance_id: template_id,
            schema_id: schema.id
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
                klass_name: klass.name,
                instance_id: template_id,
                attr: nil,
              },
            )
          end
        end

        def parent_page(params = {})
          ::Stackable::Page() do
            ::Stackable::Toolbar() do
              ::Stackable::PageHeader(title: template&.name, back: templates_location)
            end
            ::Stackable::List({
              active: params[:active],
              items: ::Settings::Schema::DocGen::Templates.children_items(schema, template.class),
              location: back_location
            })
          end
        end

        def parent_parent_page(params = {})
          CollectionPage(
            klass: schema.const::R::DocGen::Template,
            resource_id_key: :template_id,
            path_prefix: path_prefix,
            location: templates_location,
            location_suffix: '',
            scope_for_all: { klass_id: match.params[:klass_id] },
          )
        end

        def back_location
          "#{templates_location}/#{match.params[:template_id]}"
        end

      end
    end
  end
end
