class Crm
  class Planner
    class View
      class EventPreview < HyperComponent
        param :event_id
        param :klass

        before_mount do
          @preview_form = nil
          @preview_form_error = false
          @event_record = nil
          @record_not_found = false
          load_preview_form
        end

        render do
          DIV(class: 'p-3') do
            if @record_not_found
              render_not_found
            elsif @preview_form && @event_record
              render_form
            elsif @preview_form_error
              render_error
            else
              render_loading
            end
          end
        end

        def load_preview_form
          Dynamic::Form
            .where(schema_id: klass.schema_name, klass_name: klass.name, default: true)
            .with_action('show')
            .includes(includes_for_load_record: 1)
            .first do |form|
              if form
                @preview_form = form
                @preview_form_error = false
                record_includes = form.includes_for_load_record
                load_event_record(record_includes)
              else
                @preview_form_error = true
                mutate
              end
            end
          nil
        end

        def load_event_record(record_includes)
          record = klass.includes(record_includes).find(event_id)
          record.__promise__.then do
            if record.not_found?
              @record_not_found = true
            else
              @event_record = record
            end
            mutate
          end
          nil
        end

        def render_form
          Form(
            schema_id: klass.schema_name,
            dynamic_form_id: @preview_form.id,
            klass_name: klass.name,
            source_record: @event_record
          )
        end

        def render_error
          DIV(class: 'd-flex flex-column align-items-center text-muted justify-content-center') do
            I(class: 'fas fa-exclamation-circle fa-2x mb-2') {}
            SPAN { I18n.t('crm.planner.errors.no_preview_form') }
          end
        end

        def render_not_found
          DIV(class: 'd-flex flex-column align-items-center text-muted justify-content-center') do
            I(class: 'fas fa-exclamation-circle fa-2x mb-2') {}
            SPAN { I18n.t('crm.planner.errors.record_not_found') }
          end
        end

        def render_loading
          DIV(class: 'd-flex align-items-center text-muted justify-content-center') do
            SPAN(class: 'spinner-border spinner-border-sm mr-2', role: 'status', 'aria-hidden': 'true') {}
          end
        end
      end
    end
  end
end