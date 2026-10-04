# backtick_javascript: true

class Settings

  class Schema

    class Themes < Base

      render { content }

      def content
        return super unless action == 'edit'
        @current_model = nil if action_changed?
        editor
      end

      def action
        request.params[:action]
      end

      track_changes :action

      before_unmount do
        desync_theme if current_model&.community_appearance
      end

      def klass
        ::Dynamic::Theme
      end

      def new_record
        result = klass.new(
          schema_id: request.params[:schema_id],
          community_appearance: request.params[:community_appearance],
        )
        result.human_name = request.params[:human_name]
        return result
      end

      def self.children_items(schema)
        [
          {
            id: 'edit',
            icon: 'paint-brush',
            title: I18n.t('shared.edit'),
          }
        ]
      end

      def editor
        observe current_model
        return unless current_model&.loaded?
        sync_theme if current_model.community_appearance

        BootstrapEditor::Editor(
          class: "toolbar-offset-top vh-100-with-offset bg-light-yiq",
          variables: current_model.variables&.download,
          custom: current_model.custom&.download,
          back_location: location,
          save_callback: Proc.new do |variables, custom, css|
            current_model.variables.attach(`new Blob([#{variables}], {type : 'text/plain'})`)
            current_model.custom.attach(`new Blob([#{custom}], {type : 'text/plain'})`)
            next current_model.save
          end
        )
      end

      def self.includes_for_edit
        {
          variables: { include: { download: 1 } },
          custom: { include: { download: 1 } },
        }
      end

      def sync_theme
        Dynamic::Theme.includes(schema: 1).__cable__.subscribe(action: :update_appearance, on: :instance, user_id: nil)
      end

      def desync_theme
        Dynamic::Theme.includes(schema: 1).__cable__.unsubscribe(action: :update_appearance, on: :instance, user_id: nil)
      end

      class EditPanel < ::Settings::Schema::EditPanel

        render { content }

        def form
          Form(record: record, enabled: true) do
            Form::Element::Attribute::TranslatableString(
              attribute_name: 'human_name',
              auto_focus: true,
              errors_from: 'name',
            )
            Form::Element::Attribute::String(
              attribute_name: 'schema_id',
              editor: 'hidden',
            )
            Form::Element::Attribute::Boolean(
              attribute_name: 'community_appearance',
            )
            children_list
          end.on(:success) do
            ::User.current(true) do |u|
              community.update_appearance
            end
            App.history.push(record_location)
          end
        end

        def community
          ::User.current.communities&.detect{|c| c.permalink.classify_permalink == request.params[:schema_id].to_s.classify_permalink}
        end

        def footer
          form_footer
        end

      end

    end

  end

end
