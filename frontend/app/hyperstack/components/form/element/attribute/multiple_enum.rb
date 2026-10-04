# backtick_javascript: true

require 'components/form/element/attribute/enum'
require 'components/form/element/tom_select'

class Form
  module Element
    module Attribute
      class MultipleEnum < ::Form::Element::Attribute::Enum
        include TomSelect

        render { content }

        def default_editor
          'checkbox'
        end

        def render_input_checkbox
          layout_input do
            checkboxes
            input_errors
          end
        end

        def checkboxes(inline = true)
          possible_values.each do |pv|
            @current_possible_value = pv
            DIV(class: "form-check#{ inline ? '-inline' : '' }") do
              INPUT(input_args) do
              end.on(:change) do |event|
                value = Array(form&.submission&.read(path)).dup
                if checked?(pv)
                  value.delete(pv[:value])
                else
                  value << pv[:value]
                end
                change_value(value)
              end
              LABEL(class: 'form-check-label', htmlFor: input_id) do
                pv[:label]
              end
            end
          end
        end

        def checked?(pv = @current_possible_value)
          !!form&.submission&.read(path)&.include?(pv[:value])
        end

        def input_id
          @current_possible_value ? "#{super}-#{@current_possible_value[:value]}" : super
        end

        def input_args
          result = {
            id: input_id,
            name: input_name,
            value: @current_possible_value[:value],
            checked: checked?,
            type: 'checkbox',
            class: "form-check-input #{invalid_css_class}",
          }
          result[:disabled] = "disabled" if disabled_by_autocomplete || disabled
          result[:readonly] = "readonly" if disabled_by_autocomplete || readonly
          result[:"aria-describedby"] = "help-#{form_group_id}" if help.present?

          return result
        end

        def input_name
          "#{super}[]"
        end

        def render_input_select
          layout_input do
            SELECT(select_args) do
              children.render
              select_options
            end.on(:change) do |event|
              value = ::Element[event.target.to_n].value
              change_value(value)
            end
            input_errors
          end
        end

        def select_options
          special_all_option if special_all_value?
          super
        end

        def special_all_value?
          other_params.has_key?(:special_all_value) ? other_params[:special_all_value] : false
        end

        ALL = ['__all__']

        def special_all_option
          OPTION(value: ALL.first) do
            I18n.t('shared.all_f')
          end
        end

        def convert_value(value)
          if value == ALL && special_all_value?
            return []
          else
            super
          end
        end

        def select_empty_value
          # redefined no empty value
        end

        def select_args # for editor == select
          r = super
          r.merge!(multiple: true)
          r[:defaultValue] = r.delete(:value) || []
          r[:defaultValue] = ALL if r[:defaultValue] == [] && special_all_value?
          r
        end

        def render_input_select2
          layout_input do
            SELECT(select_args) do
              children.render
              select_options
            end
            input_errors
          end
        end

        def tom_select_options
          {
            plugins: {
              remove_button: { # add remove buttons on items
                title: I18n.t('shared.delete'),
              }
            },
          }
        end

        def selected_values
          return [] unless form
          possible_values.select{|pv| form.submission.read(path)&.include?(pv[:value])  }
        end

      end
    end
  end
end
