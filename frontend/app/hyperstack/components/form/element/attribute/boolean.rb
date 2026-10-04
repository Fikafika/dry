require 'components/form/element/attribute/enum'

class Form
  module Element
    module Attribute
      class Boolean < ::Form::Element::Attribute::Enum

        render { content }
        param :serialized, default: true

        def default_editor
          'checkbox'
        end

        def render_input_checkbox
          layout_input_checkbox do
            INPUT(input_args).on(:change) do |event|
              change_value(checked? ? '0' : '1')
            end
          end
        end

        def render_input_switch
          layout_input do
            DIV(ref: _ref, class: "row form-group #{requirement}") do
              DIV(class: "col-md-9") do
                DIV(class: 'form-check slider-button') do
                  INPUT(input_switch_args).on(:change) do |event|
                    change_switch_value(event.current_target.value)
                  end
                  input_errors
                end
              end
            end
          end
        end

        def switch_step
          return @switch_step if @switch_step
          if requirement == 'mandatory'
            @switch_step = 1
          else
            @switch_step = 0.5
          end
        end

        def input_switch_args
          result = {
            type: 'range',
            min: 0,
            step: switch_step,
            max: 1,
            value: convert_not_serialized_value(form.submission.read(path)),
            class: "form-control p-0 #{invalid_css_class} #{bg_color}"
          }
          result[:disabled] = "disabled" if disabled_by_autocomplete || disabled
          result[:readonly] = "readonly" if disabled_by_autocomplete || readonly
          result[:"aria-describedby"] = "help-#{form_group_id}" if help.present?

          return result
        end

        def convert_not_serialized_value(value)
          unless serialized
            if value == true
              return '1'
            elsif value == false
              return '0'
            end
          end
          value
        end

        def bg_color
          case form.submission.read(path)
          when '1'
            'bg-success'
          when nil, '0.5'
            'bg-secondary'
          when '0'
            'bg-danger'
          end
        end

        def layout_input_checkbox
          DIV(ref: _ref, class: "row form-group #{requirement}") do
            DIV(class: "#{input_col_size} #{offset_size}") do
              DIV(class: 'form-check') do
                if help.present? && help_position == 'top'
                  SMALL(class: "form-text", dangerously_set_inner_HTML: { __html: help })
                end
                yield
                LABEL(class: "form-check-label #{'control-label' if show_value}", htmlFor: input_id) do
                  displayed_label if show_value
                end
                if help.present?
                  if help_position == 'bottom'
                    SMALL(class: "form-text", dangerously_set_inner_HTML: { __html: help })
                  elsif help_position == 'icon'
                    I(class: 'fa fa-fw fa-question-circle pl-2 align-self-center', 'data-toggle': 'tooltip', title: help, "data-html": true)
                    after(0.1) do
                      jq_node.find('[data-toggle="tooltip"]').tooltip('dispose')
                      jq_node.find('[data-toggle="tooltip"]').tooltip()
                    end
                  end
                end
                input_errors
              end
            end
          end
        end

        def offset_size
          if other_params[:label_col_size]
            other_params[:label_col_size].sub('col-', 'offset-')
          else
            'offset-md-3'
          end
        end

        def input_args
          value = form.submission.read(path)
          if value == true
            value = '1'
          elsif value == false
            value = '0'
          end
          result = {
            id: input_id,
            name: input_name,
            value: value,
            type: 'checkbox',
            class: "form-check-input #{invalid_css_class}",
          }
          result[editor == 'hidden' ? :defaultChecked : :checked] = checked?
          result[:disabled] = "disabled" if disabled_by_autocomplete || disabled
          result[:readonly] = "readonly" if disabled_by_autocomplete || readonly
          result[:"aria-describedby"] = "help-#{form_group_id}" if help.present?

          return result
        end

        def checked?(pv = {value: '1'})
          old_value = form&.submission&.read(path)
          if old_value == true || old_value == false
            return old_value
          else
            return old_value == pv[:value]
          end
        end

        def possible_values
          return [
            { value: '1', label: I18n.t('shared._yes').capitalize },
            { value: '0', label: I18n.t('shared._no').capitalize },
          ]
        end

        def edit_in_place_displayed_value
          if form.submission.read(path) == '1'
            return I18n.t('shared._yes').capitalize
          else
            return I18n.t('shared._no').capitalize
          end
        end

        def convert_value(value)
          if editor == 'switch' && !form.submission.has_key?(path) && value.nil?
            if requirement == 'mandatory'
              if serialized
                return '0'
              else
                return false
              end
            else
              return nil
            end
          end
          unless serialized
            if value == '1' || value == true
              return true
            else
              return false
            end
          end
          if value.is_a?(::Boolean)
            return (value == true ? '1' : '0')
          else
            return super(value)
          end
        end

        def change_value(value)
          return unless form && !form.reseting?
          old_value = form.submission.read(path)
          new_value = convert_value(value)
          if new_value != old_value
            form.enable
            form.submission.write_from_user(path, new_value)
            checked?(value)
            change_data(value)
            mutate
            change!(value, form, self)
            form.change
          end
        end

        def render_edit_in_place_editing_checkbox
          DIV(class: 'form-control form-check') do
            INPUT(input_args).on(:change) do |event|
              change_value(checked? ? '0' : '1')
            end.on(:change) do |event|
              value = checked? ? '0' : '1'
              change_value(value)
              edit_in_place_submit_value(value)
            end
          end
        end

        def input_switch
          DIV(class: 'form-control form-check slider-button') do
            INPUT(input_switch_args).on(:change) do |event|
              change_switch_value(event.current_target.value)
            end.on(:change) do |event|
              value = event.current_target.value
              change_value(value)
              edit_in_place_submit_value(value)
            end
          end
        end

        def change_switch_value(value)
          if value == '0.5'
            change_value(nil)
          else
            change_value(value)
          end
        end

        def render_edit_in_place_not_editing_switch
          input_switch
        end
      end
    end
  end
end
