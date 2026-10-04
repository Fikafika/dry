ActiveSupport.on_load(:dynamic_schema_attachment_base) do

  concerning :AttachmentChangeUpdateDefaultForms do
    included do
      attr_accessor :skip_create_default_forms
      after_create :update_default_forms, unless: :skip_create_default_forms
      after_destroy :update_default_forms

      def update_default_forms
        update_default_form(:new, :input)
        update_default_form(:edit, :edit_in_place)
        update_default_form(:show, :read_only)
        update_default_form(:submit_all, :input)
      end

      def update_default_form(action, mode)
        #schema.load unless schema.loaded? # TODO

        klass_name = self.owner_klass.const_absolute_name

        form = schema.forms.with_action(action).where(
          default: true,
          mode: mode,
          updated_when_schema_is_changed: true,
          klass_name: klass_name,
        ).first

        return unless form

        if deleted?
          form.elements.where(
            klass_name: klass_name,
            attribute_name: self.name,
          ).destroy_all

          return
        end

        element = form.elements.where(
          klass_name: klass_name,
          attribute_name: self.name,
        ).first

        unless element
          if ("Dynamic::Form::Element::Attachment::#{self.type}".constantize rescue false)
            element_type = "Attachment::#{self.type}"
          else
            return
          end

          form.elements.create!(
            root_klass_name: klass_name,
            klass_name: klass_name,
            attribute_name: self.name,
            type: element_type
          )
        end
      end

    end
  end

  concerning :NamePreviouslyWas do # remove this concern after migration to rails 6.1+
    def name_previously_was
      self.previous_changes['name'].try(:first)
    end
  end

  concerning :Includes do
    class_methods do
      def active_storage_includes
        {
          only: ["id"],
          include: {
            blob: {
              only: ['id', "filename", "content_type", "byte_size"]
            }
          }
        }
      end
    end
  end
end
