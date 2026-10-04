class Settings

  class Schema

    class Base < ::Settings::Base

      before_update do
        if schema&.not_found?
          App.history.push(schemas_location)
        end
      end

      render { content }

      def schema
        observe @schema = Dynamic::Schema.load(match.params['schema_id'])
      end

      def schema_location
        path_prefix.include?(':schema_id/') ? base_location : "#{schemas_location}/#{match.params[:schema_id]}"
      end

      def schemas_location
        path_prefix.include?(':schema_id/') ? base_location : "#{base_location}/schemas"
      end

      def back_location
        schema_location
      end

      def parent_page(params = {})
        schema_page(params)
      end

      def schema_page(params = {})
        ::Stackable::Page(col: params[:col]) do
          schema

          ::Stackable::Toolbar() do
            ::Stackable::PageHeader(title: schema.name, back: back_location) do
              action_menu
            end
          end
          ::Stackable::List({
            active: params[:active],
            items: ::Settings::Schemas.children_items(schema),
            location: back_location
          })
        end
      end

      def new_record
        klass.new(schema_id: schema.id) # TODO how to make schema.klasses.new work with opal ?
      end

      def scope_for_all
        match.params.slice(:schema_id)
      end

      def self.includes_for_all
        { include: { translations: 1 } }
      end

      def edit_panel
        EditPanel(record: current_model, path: "#{index_location}/:id", schema: schema)
      end

      def action_menu
        ActionMenu(schema: schema)
      end

      def list_page
        CollectionPage(
          klass: klass,
          resource_id_key: resource_id_key,
          path_prefix: path_prefix,
          location: index_location,
          scope_for_all: scope_for_all,
          includes_for_all: includes_for_all,
          editable: editable?,
          schema: schema,
        )
      end

    end

    class CollectionPage < ::Settings::CollectionPage

      render { content }

      param :schema, default: nil

      def content
        observe schema
        super
      end

    end

    class EditPanel < ::Settings::EditPanel

      render { content }

      param :schema, default: nil

      def content
        observe schema
        super
      end

      def children_items
        return [] unless self.class.parent.respond_to?(:children_items)
        return self.class.parent.children_items(schema, record)
      end

      def comment
        Form::Element::Attribute::Text(
          attribute_name: 'comment',
        )
      end

    end

  end

end
