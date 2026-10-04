require 'components/form/element/attribute/base'

class Form
  module Element
    module Attribute
      class Enum < ::Form::Element::Attribute::Base

        param :show_value, default: true
        param :value_position, default: nil
        param :css_classes, default: nil

        render { content }

        def default_editor
          'select'
        end

        def possible_values
          p = other_params[:possible_values]
          result = p.is_a?(Proc) ? p.call(form, prefix_path) : p
          return result if result&.any?
          return self.class.possible_values(record_klass, attribute_name)
        end

        def self.possible_values(record_klass, attribute_name)
          values_method = attribute_name.pluralize
          if record_klass.respond_to?(values_method)
            result = record_klass.send(values_method).map do |k|
              k = k.first if k.is_a?(::Array)
              { value: k, label: record_klass.human_attribute_value(attribute_name, k) }
            end
            return result
          end
          return []
        end

        def render_input_select
          layout_input do
            SELECT(select_args) do
              children.render
              select_options
            end.on(:change) do |event|
              change_value(event.target.value)
            end
            input_errors
          end
        end

        def select_args
          result = {
            name: input_name,
            value: form&.submission&.read(path),
            class: "form-control #{invalid_css_class}",
          }
          result[:disabled] = "disabled" if disabled_by_autocomplete || disabled
          result[:readonly] = "readonly" if disabled_by_autocomplete || readonly
          result[:"aria-describedby"] = "help-#{form_group_id}" if help.present?
          return result
        end

        def select_options
          select_empty_value
          possible_values.each_with_index do |pv, i|
            OPTION(key: "#{form_group_id}-#{i}", value: pv[:value]) do
              pv[:label]
            end
          end
        end

        def select_empty_value
          return unless possible_values.any?
          return if dont_accept_empty_value_and_value_not_assigned?
          OPTION(key: "#{form_group_id}-empty", value: '') do
            placeholder_
          end
        end

        def dont_accept_empty_value_and_value_not_assigned?
          !accept_empty_value? && !form&.submission&.read(path).nil?
        end

        def accept_empty_value?
          other_params.has_key?(:accept_empty_value) ? other_params[:accept_empty_value] : true
        end

        def convert_value(value)
          return super if value.nil? || value == ''
          match = possible_values.find { |pv| pv[:value].to_s == value.to_s }
          match ? match[:value] : super
        end

        # ----------------------------------------------------------------------
        def render_input_step_inline
          render_input_step(true)
        end

        def render_input_step(inline = false)
          layout_input do
            step_input(inline)
          end
        end

        def step_input(inline = false)
          DIV(step_args(inline)) do
            possible_values.each_with_index.map do |item, index|
              @done = possible_values.slice(index..-1).any? { |h| h["value"] == form&.submission&.read(path) }
              if inline
                DIV(class: 'container container-wrapper pl-0 mr-2') do
                  DIV(class: "step-list-text-inline") { item[:label] }
                  DIV(class: "step-list-item-inline#{' done' if @done}") do
                    DIV(class: "step-list-bullet-elements") do
                      DIV(class: "d-flex w-100") do
                        if index > 0
                          DIV(class: "step-list-bar #{'done' if @done}")
                        end
                        DIV(class: "step-list-bullet")
                      end
                    end
                  end
                end.on(:click) do
                  change_step_value(item[:value])
                end
              else
                DIV(class: "step-list-item#{' done' if @done}") do
                  DIV(class: "step-list-bullet")
                  DIV(class: "step-list-text") { item[:label] }
                end.on(:click) do
                  change_step_value(item[:value])
                end
              end
            end
          end
        end

        def render_edit_in_place_editing_step_inline
          step_input(true)
        end

        def render_edit_in_place_not_editing_step_inline
          step_input(true)
        end

        def render_edit_in_place_editing_step
          step_input
        end

        def render_edit_in_place_not_editing_step
          step_input
        end

        def step_args(inline)
          result = {
            name: input_name,
            value: form&.submission&.read(path),
            class: "step-list#{'-inline' if inline} step-list-primary"
          }
          result[:disabled] = "disabled" if disabled_by_autocomplete || disabled
          result[:readonly] = "readonly" if disabled_by_autocomplete || readonly
          result[:"aria-describedby"] = "help-#{form_group_id}" if help.present?
          return result
        end

        def change_step_value(value)
          change_value(value)
          if mode == "edit_in_place"
            edit_in_place_submit_value(value)
          end
        end

        # ----------------------------------------------------------------------


        def render_input_radio(inline = false)
          layout_input do
            if value_position == 'top' && inline == true
              # TODO improve this mode
              DIV(class: 'text-left') do
                possible_values.each_with_index do |pv, i|
                  id = value_id(i)
                  SPAN(class: "text-center") do
                    DIV(class: "form-check form-check-inline") do
                      LABEL(class: '', htmlFor: id) do
                        DIV(class: show_value ? 'no-height' : '') do # TODO class no-height
                          show_value ? pv[:label] : ''
                        end
                        INPUT(input_radio_args.merge(id: id, checked: checked?(pv), value: pv[:value], class: " #{invalid_css_class}")).on(:change) do |event|
                          change_value(pv[:value])
                        end
                      end
                    end
                    LABEL(class: '') do
                      ''
                    end
                  end
                end
              end
            elsif value_position == 'top' && inline == false
              possible_values.each_with_index do |pv, i|
                id = value_id(i)
                DIV(class: "form-check #{inline ? 'form-check-inline' : ''}") do
                  SPAN(class: "text-center") do
                    LABEL(class: '', htmlFor: id) do
                      DIV(class: show_value ? 'no-height' : '') do # TODO class no-height
                        show_value ? pv[:label] : ''
                      end
                      INPUT(input_radio_args.merge(id: id, checked: checked?(pv), value: pv[:value], class: " #{invalid_css_class}")).on(:change) do |event|
                        change_value(pv[:value])
                      end
                    end
                  end
                end
              end
            elsif (value_position == 'right' || value_position.nil?) && inline == true
              DIV(class: 'text-left') do
                possible_values.each_with_index do |pv, i|
                  id = value_id(i)
                  DIV(class: "form-check #{inline ? 'form-check-inline' : ''}") do
                    INPUT(input_radio_args.merge(id: id, checked: checked?(pv), value: pv[:value])).on(:change) do |event|
                      change_value(pv[:value])
                    end
                    LABEL(class: 'form-check-label', htmlFor: id) do
                      show_value ? pv[:label] : ''
                    end
                  end
                end
              end
            elsif (value_position == 'right' || value_position.nil?) && inline == false
              possible_values.each_with_index do |pv, i|
                id = value_id(i)
                DIV(class: "form-check #{inline ? 'form-check-inline' : ''}") do
                  INPUT(input_radio_args.merge(id: id, checked: checked?(pv), value: pv[:value])).on(:change) do |event|
                    change_value(pv[:value])
                  end
                  LABEL(class: 'form-check-label', htmlFor: id) do
                    show_value ? pv[:label] : ''
                  end
                end
              end
            end
            input_errors
          end
        end

        def checked?(pv)
          form&.submission&.read(path) == pv[:value]
        end

        def input_radio_args
          result = {
            name: input_name,
            type: 'radio',
            class: "form-check-input #{invalid_css_class}",
          }
          result[:disabled] = "disabled" if disabled_by_autocomplete || disabled
          result[:readonly] = "readonly" if disabled_by_autocomplete || readonly
          result[:"aria-describedby"] = "help-#{form_group_id}" if help.present?
          return result
        end

        # ----------------------------------------------------------------------

        def render_input_radio_inline
          render_input_radio(true)
        end

        def render_edit_in_place_editing
          send(:"render_edit_in_place_editing_#{editor || default_editor}")
        end

        def render_edit_in_place_not_editing
          m = :"render_edit_in_place_not_editing_#{editor || default_editor}"
          respond_to?(m) ? send(m) : super
        end

        def render_edit_in_place_not_editing_select
          DIV(class: @edit ? '' : 'hover-show-edit-icon') do
            SELECT(select_args.merge(class: "form-control #{css_classes&.dig(:field_size)} border-0 px-0 bg-transparent #{' cursor-text' unless @edit}")) do
              children.render
              select_options
            end.on(:change) do |event|
              event.target.blur
              change_value(event.target.value)
              edit_in_place_submit_value(event.target.value)
            end.on(:focus) do
              mutate @edit = true
            end.on(:blur) do
              mutate @edit = false
            end
            input_errors
            edit_in_place_icon
          end
        end

        def render_edit_in_place_editing_select
          render_edit_in_place_not_editing_select # same
        end

        def render_edit_in_place_editing_radio(inline = false)
          DIV(class: 'pt-2') do
            possible_values.each_with_index do |pv, i|
              id = value_id(i)
              DIV(class: "form-check #{inline ? 'form-check-inline' : ''}") do
                INPUT(input_radio_args.merge(id: id, checked: checked?(pv), value: pv[:value])).on(:change) do |event|
                  change_value(pv[:value])
                  edit_in_place_submit_value(event.target.value)
                end
                LABEL(class: 'form-check-label', htmlFor: id) do
                  pv[:label]
                end
              end
            end
          end
        end

        def render_edit_in_place_editing_radio_inline
          render_edit_in_place_editing_radio(true)
        end

        def render_diff
        end

        # ----------------------------------------------------------------------

        def radio_cards_input(inline = false)
          DIV(class: "container d-flex justify-content-center") do
            DIV(cards_args(inline)) do
              possible_values.each_with_index.map do |item, index|
                selected = form&.submission&.read(path) == item[:value]

                DIV(class: "card text-center #{'border-primary' if selected} cursor-pointer", style: {borderWidth: "2px"}) do
                  DIV(class: "card-header", style: {aspectRatio: "1/0.75"}) do
                    show_value ? I(class: "fa-solid fa-#{item[:icon]} text-primary d-flex align-items-center justify-content-center h-100 w-100 fa-5x") : ''
                  end

                  DIV(class: "card-body") do
                    show_value ? item[:label] : ''
                  end

                  if selected
                    DIV(class: "position-absolute m-2", style: {top: 0, right: 0}) do
                      I(class: "fa-solid fa-circle-check text-primary d-flex align-items-center justify-content-center h-100 w-100", style: {fontSize: "1.5em"})
                    end
                  end
                end.on(:click) do
                  change_value(item[:value])
                  edit_in_place_submit_value(item[:value]) if mode == "edit_in_place"
                end
              end
            end
          end
        end

        def render_input_radio_card(inline = false)
          radio_cards_input(inline)
        end

        def render_input_radio_card_inline
          radio_cards_input(true)
        end

        def render_edit_in_place_editing_cards(inline = false)
          radio_cards_input(inline)
        end

        def render_edit_in_place_not_editing_cards(inline = false)
          radio_cards_input(inline)
        end

        def cards_args(inline)
          result = {
            name: input_name,
            value: form&.submission&.read(path),
            class: "w-75 overflow-auto m-3",
            style: {
              display: "grid",
              gridTemplateColumns: "repeat(3, minmax(0,1fr))",
              maxHeight: "75vh",
              gap: "16px",
            }
          }
          result[:disabled] = "disabled" if disabled_by_autocomplete || disabled
          result[:readonly] = "readonly" if disabled_by_autocomplete || readonly
          result[:"aria-describedby"] = "help-#{form_group_id}" if help.present?
          return result
        end

        # read only --------------------------------------------------------------------------

        def read_only_displayed_value
          possible_values.detect do |pv|
            pv[:value] == form.submission.read(path)
          end.try(:[], :label)
        end

        # edit cell --------------------------------------------------------------------------

        def render_edit_cell
          layout_edit_cell do
            SELECT(select_args.merge(class: "form-control border-0 px-0")) do
              children.render
              select_options
            end.on(:change) do |event|
              event.target.blur
              change_value(event.target.value)
              edit_in_place_submit_value(event.target.value)
            end
          end
        end

      end
    end
  end
end
