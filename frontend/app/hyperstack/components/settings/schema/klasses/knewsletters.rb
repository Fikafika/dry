class Settings

  class Schema

    class Knewsletters < Klasses::Base

      render { content }

      def content
        observe schema

        if schema.constants_loaded? && schema.has_feature_enabled?('Dynamic::Knewsletter::Feature')
          super
        else
          DIV() do
          end
        end
      end

      def klass
        schema.const::R::Knewsletter::RecipientPath
      end

      def new_record
        klass.new
      end

      def scope_for_all
        {
          "schema" => schema.name.downcase,
          "klass" => match.params['klass_id'].pluralize,
        }
      end

      def self.children_items
        []
      end

      class EditPanel < ::Settings::Schema::EditPanel

        render { content }

        def form
          Form(record: record) do
            Form::Element::Attribute::String(
              attribute_name: 'schema',
              default_value: schema.name.downcase,
              editor: 'hidden',
            )
            Form::Element::Attribute::String(
              attribute_name: 'klass',
              default_value: klass.pluralize,
              editor: 'hidden',
            )
            Form::Element::Attribute::String(
              attribute_name: 'name',
            )

            Form::Element::Attribute::String(
              attribute_name: 'formula',
            )

            children_list
          end.on(:success) do
            App.history.push(record_location)
          end
        end

        def footer
          form_footer
        end

        def klass
          path.split('/')[5]
        end

      end

    end

  end

end
