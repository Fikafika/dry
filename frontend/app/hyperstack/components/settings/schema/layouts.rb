class Settings

  class Layouts < ::Settings::Schema::Base

    render { content }

    def klass
      ::Dynamic::Layout
    end

    def new_record
      klass.new({
        schema_id: match.params['schema_id'],
      })
    end

    class EditPanel < ::Settings::Schema::EditPanel

      render { content }

      def form
        Form(record: record) do
          Form::Element::Attribute::TranslatableString(
            attribute_name: 'human_name',
            auto_focus: true,
            errors_from: 'name',
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
