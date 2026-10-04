class Settings

  class Schema

    class Layouts < Klasses::Base

      render { content }

      def content
        if request.params[:action] == 'edit'
          layout do
            Editor()
          end
        else
          super
        end
      end

      def klass
        ::Dynamic::Layout
      end

      def new_record
        klass.new({
          schema_id: match.params['schema_id'],
          klass_id: match.params['klass_id'],
          klass_name: schema_klass_name,
        })
      end

      def scope_for_all
        super.merge(klass_name: schema_klass_name)
      end

      def self.children_items
        [
          {
            id: 'edit',
            icon: 'paint-brush',
            title: I18n.t('shared.edit'),
          }
        ]
      end

      class EditPanel < ::Settings::Schema::EditPanel

        render { content }

        def form
          Form(record: record) do
            Form::Element::Attribute::String(
              attribute_name: 'klass_name',
              editor: 'hidden',
            )
            Form::Element::Attribute::TranslatableString(
              attribute_name: 'human_name',
              auto_focus: true,
              errors_from: 'name',
            )
            Form::Element::Attribute::MultipleEnum(
              attribute_name: 'actions',
            )
            children_list
          end.on(:success) do
            App.history.push(record_location)
          end
        end

        def footer
          form_footer
        end

      end

    end

  end

end
