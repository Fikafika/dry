class Form
  module Element
    module Association
      class BelongsTo < Base

        render { content }

        def association_name
          return attribute_name unless attribute_name.end_with?('_id')
          return attribute_name.gsub(/_id$/, '')
        end

        def record_association_attributes
          t = record.send(association_name)
          result = t ? [record_attributes(t)] : []

          if result.empty? && association_min && association_min >= 1
            result <<  attrs_for_new_record.dup
          end
          return result
        end

        # input ------------------------------------------------------------------

        def select_args
          super.merge({
            defaultValue: selected_values.first.try(:[], :value),
          })
        end

        def selected_values
          return [] unless form
          id = form.submission.read_id(path)
          if id
            d = form.submission.data.dig(input_prefix, attribute_name)
            d = nil unless d&.id == id
            [{ value: id, label: record_name(d) }]
          else
            []
          end
        end

        def value_from_tom_select_data
          super.first
        end

        def convert_value(value)
          if attribute_name.end_with?('_id')
            convert_value_to_id(value)
          else
            return {} unless value
            if polymorphic?
              return { 'id' => value.id, 'type' => value.class.name }
            else
              return { 'id' => value.id }
            end
          end
        end

        def convert_value_to_id(value)
          return value if id?(value)
          return value&.id
        end

        def edit_in_place_displayed_value
          DIV(class: 'text-truncate', title: record_name(record.send(association_name))) do
            read_only_displayed_value
          end
        end

        # edit in place --------------------------------------------------------

        def render_edit_in_place_not_editing
          edit_in_place_fake_input do
            edit_in_place_value_container do
              empty_and_show_placeholder? ? placeholder : edit_in_place_displayed_value
            end
          end.on(:click) do |event|
            event.prevent_default
            @edit = true
            mutate
          end
        end

        def render_edit_in_place_editing
          InputWithAutocomplete({
            input_args: edit_in_place_input_args,
            search_url: target_klass_search_url,
            process_params: Proc.new { |params| add_autocomplete_variables_to_params(params) },
            template_result: self.class.template_result_ruby(target_klass),
            autofocus: true,
          }).on(:focus) do |event|
            @original_value = record.send(association_name)
          end.on(:blur) do |event|
            after(0.1) do
              @edit = false
              mutate
            end
          end.on(:key_enter) do |event, value|
            selected_record = value ? polymorphic_new(value['record']) : nil
            edit_in_place_submit_value(selected_record)
          end.on(:key_escape) do |event|
            change_data(@original_value)
            @edit = false
            mutate
          end.on(:select) do |event, value|
            edit_in_place_submit_value(selected_record(value))
          end
        end

        def edit_in_place_params_for_update(value)
          if polymorphic?
            return { attribute_name_for_update => convert_value_to_id(value), attribute_name_for_update.gsub(/_id$/, '_type') => value&.class&.name }
          else
            return { attribute_name_for_update => convert_value_to_id(value) }
          end
        end

        def edit_in_place_input_args
          a = record.send(association_name)
          result = {
            id: edit_in_place_input_id,
            class: "form-control #{invalid_css_class}",
            defaultValue: a ? record_name(a) : nil,
          }
          result[:disabled] = "disabled" if disabled
          result[:readonly] = "readonly" if readonly
          result[:"aria-describedby"] = "help-#{form_group_id}" if help.present?
          return result
        end

        def attribute_name_for_update
          attribute_name.end_with?('_id') ? attribute_name : "#{attribute_name}_id"
        end

        def empty_and_show_placeholder?
          record.send(association_name).blank?
        end

        # radio -------------------------------------------------------------------

        def render_input_radio(inline = false)
          layout_input do
            render_possible_values_or_records(inline) do |id, value|
              input_radio(id, value)
            end
            input_errors
          end
        end

        def input_radio(id, value)
          INPUT(input_radio_args.merge(id: id, checked: checked?(value), value: value.id)).on(:change) do |event|
            change_value(value)
          end
        end

        def checked?(pv)
          id = form&.submission&.read_id(path)
          return !!(id && id == pv[:value].id) if pv[:value]
          return !!(id && id == pv.id)
        end

        def input_radio_args
          result = {
            name: input_name,
            type: 'radio',
            class: "form-check-input #{invalid_css_class}",
          }
          result[:disabled] = "disabled" if disabled
          result[:readonly] = "readonly" if readonly
          result[:"aria-describedby"] = "help-#{form_group_id}" if help.present?
          return result
        end

        def possible_values
          return other_params[:possible_values] if other_params[:possible_values]&.any?
          return []
        end

        def render_input_radio_inline
          render_input_radio(true)
        end

        # step -------------------------------------------------------------------

        def change_step_value(value)
          if mode == 'edit_in_place'
            @original_value = record.send(association_name)
            edit_in_place_submit_value(value)
          else
            change_value(value)
          end
        end

        # read only ---------------------------------------------------------------

        def read_only_displayed_value
          value = record.send(association_name)
          return unless value
          render_item(value)
        end

        # nested form -------------------------------------------------------------

      end
    end
  end
end
