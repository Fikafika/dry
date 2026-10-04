class Settings
  class Schema
    class Forms
      class Base < Klasses::Base

        def form_id
          match.params[:form_id]
        end

        def parent_page(params = {})
          form_page(params)
        end

        def form_page(params = {})
          ::Stackable::Page() do
            ::Stackable::Toolbar() do
              ::Stackable::PageHeader(title: form.human_name, back: parent_back_location)
            end
            ::Stackable::List({
              active: params[:active],
              items: ::Settings::Schema::Forms.children_items(schema),
              location: back_location
            })
          end
        end

        def back_location
          "#{forms_location}/#{form_id}"
        end

        def parent_back_location
          forms_location
        end

        def form
          observe @form = Dynamic::Form.where({
            schema_id: match.params['schema_id'],
            klass_id: match.params['klass_id'],
          }).find(form_id)
        end

        def forms_location
          "#{schema_location}/klasses/#{match.params['klass_id']}/forms"
        end

        def path_prefix
          "#{super}/forms/#{form_id}"
        end

        def parent_parent_page(params = {})
          CollectionPage(
            klass: Dynamic::Form,
            resource_id_key: :form_id,
            path_prefix: path_prefix,
            location: forms_location,
            location_suffix: parent_parent_location_suffix,
            scope_for_all: {schema_id: match.params[:schema_id], klass_id: match.params[:klass_id], klass_name: schema_klass_name}, #TODO immprove forms controller for klass/id
            includes_for_all: { include: { translations: 1 } },
            schema: schema,
          )
        end

      end
    end
  end
end