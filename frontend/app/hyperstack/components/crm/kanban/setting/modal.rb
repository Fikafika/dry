require 'components/crm'

class Crm
  class Kanban
    module Setting
      class Modal < ::Modal
        param :klass

        render { content }

        def body
          Crm::Kanban::Setting::Form(
            form_ref: form_ref,
            klass: klass, schema: schema,
            mode: :edit,
            dynamic_layout: dynamic_layout,
            column_settings: column_settings,
          ).on(:change) do |confirm_enabled|
            @confirm_enabled = confirm_enabled
            mutate
          end.on(:save) do
            # Put it this way because history.replace can't close the modal so directly close first
            close
            confirm!
          end
        end

        def confirm_enabled?
          @confirm_enabled
        end

        def form_ref
          @form_ref ||= {}
        end

        def form
          @form_ref[:current]
        end

        def title
          I18n.t('crm.kanban.setting.title')
        end

        def dynamic_layout
          other_params[:dynamic_layout]
        end

        def schema
          other_params[:schema]
        end

        def column_settings
          other_params[:column_settings]
        end

        def confirm
          form&.save_setting
        end

      end
    end
  end
end
