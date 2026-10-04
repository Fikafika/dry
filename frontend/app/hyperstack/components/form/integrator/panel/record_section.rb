class Form
  class Integrator
    module Panel
      class RecordSection < HyperComponent
        param :type
        param :record_type
        param :record_id
        param :belongs_to_id

        fires :id_change

        before_mount do
          @edit_mode = {}
        end

        render do
          render_record_id_selector
        end

        private

        def render_record_id_selector
          DIV(class: 'form-group') do
            LABEL { I18n.t("crm.form_integrator.#{type}_record_id.label") }
            target_klass = record_type.present? ? record_type.safe_constantize : nil
            if record_id.present? && !@edit_mode["#{type}_record_iframe"] && target_klass
              render_selected_record(target_klass)
            else
              render_record_input(target_klass)
            end
          end
        end

        def render_selected_record(target_klass)
          record = target_klass.find(record_id)
          record_name = record.try(:name) || record.try(:polymorphic_name) || record.id.to_s
          DIV(
            class: 'form-control d-flex justify-content-between align-items-center h-auto',
            style: {cursor: 'pointer'}
          ) do
            SPAN { record_name }
            SPAN(class: 'text-primary ml-2') do
              I(class: 'fas fa-pencil-alt')
            end
          end.on(:click) do
            @edit_mode["#{type}_record_iframe"] = true
          end
          mutate
        end

        def render_record_input(target_klass)
          component_key = "belongs-to-#{type}-#{record_type}-#{belongs_to_id}"
          DIV(
            id: belongs_to_id,
            class: "input--#{type}_record",
            key: "belongs-to-container-#{record_type}"
          ) do
            if record_id && target_klass
              target_class_record = target_klass.find(record_id)
              Form.current.submission.data[nil] ||= {}
              Form.current.submission.data[nil]["#{type}_record_iframe"] = target_class_record
            end

            if record_id.present?
              render_back_button
            end

            Form::Element::Association::BelongsTo(
              key: component_key,
              attribute_name: "#{type}_record_iframe_id",
              target_klass: target_klass,
              form: Form.current,
              show_label: false,
              disabled: target_klass.nil?
            ).on(:change) do |e|
              id_change!(e)
            end
          end
        end

        def render_back_button
          DIV(class: 'mb-2') do
            BUTTON(type: 'button', class: 'btn btn-sm btn-outline-secondary') do
              I(class: 'fas fa-arrow-left mr-1')
              SPAN { I18n.t("crm.form_integrator.back") }
            end.on(:click) do
              @edit_mode["#{type}_record_iframe"] = false
              mutate
            end
          end
        end
      end
    end
  end
end
