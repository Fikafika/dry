class Settings

  class Schemas < Base

    render { content }

    def klass
     ::Dynamic::Schema
    end

    def scope_for_all
      {}
    end

    def self.includes_for_all
      { include: { translations: 1 } }
    end

    def self.children_items
      [
        ::Settings::Schema::Appearance.item,
      ] + [
        ::Dynamic::Schema::Klass,
        ::Dynamic::Schema::Feature,
        ::Dynamic::Theme,
        ::Dynamic::Redirection,
        ::UneekPermission::Rule,
        #::Dynamic::Schema::Migration::Base,
      ].map do |a|
        {
          id: resources_name(a),
          icon: a.icon,
          title: a.model_name.human(count: 2),
        }
      end
    end

    class EditPanel < ::Settings::EditPanel

      render { content }

      def form
        Form(record: record) do
          Form::Element::Attribute::TranslatableString(
            attribute_name: 'human_name',
            errors_from: 'name',
            auto_focus: true,
          )
          Form::Element::Attribute::Text(
            attribute_name: 'comment',
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
