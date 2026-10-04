class Crm
  class Planner
    class SettingsDialog < ::Modal
      param :query_record
      param :search_query

      fires :apply

      def title
        I18n.t('crm.planner.modal.settings')
      end

      def body
        DIV(class: 'p-3') { render_form }
      end

      def footer
        DIV(class: 'd-flex justify-content-end') do
          cancel_button
          apply_button
        end
      end

      def render_form
        Form(
          record: query_record,
          default_values: { params: search_query.params || {} },
          class: 'px-3 pb-3'
        ) do
          settings_form_fields
        end
          .on(:success) { handle_form_success }
          .on(:loaded) { |form| @form = form }
      end

      def settings_form_fields
        Form::Element::Attribute::Hash(attribute_name: 'params', mode: 'nested_form') do
          Form::Element::Attribute::Hash(attribute_name: 'planner', mode: 'nested_form') do
            Form::Element::Attribute::TimeOfDay(
              attribute_name: 'min_day_time',
              label: I18n.t('crm.query.params.planner.min_day_time')
            )
            Form::Element::Attribute::TimeOfDay(
              attribute_name: 'max_day_time',
              label: I18n.t('crm.query.params.planner.max_day_time')
            )
            Form::Element::Attribute::TimeOfDay(
              attribute_name: 'event_duration',
              label: I18n.t('crm.query.params.planner.event_duration'),
            )
            Form::Element::Attribute::Date(
              attribute_name: 'last_date',
              label: I18n.t('crm.query.params.planner.last_date_viewed')
            )
          end
        end
      end


      private


      def apply_settings
        @form ? @form.submit : close
      end

      def handle_form_success
        new_params = @form&.submission&.params&.dig('base', 'params')
        apply!(new_params) if new_params
        close
      end

      def cancel_button
        BUTTON(
          class: 'btn btn-secondary mr-2',
          type: 'button',
          'data-dismiss': 'modal'
        ) { I18n.t('shared.cancel') }
      end

      def apply_button
        BUTTON(class: 'btn btn-primary', type: 'button') do
          I18n.t('shared.apply')
        end.on(:click) { apply_settings }
      end
    end
  end
end