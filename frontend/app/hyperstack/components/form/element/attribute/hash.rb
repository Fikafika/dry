require 'components/form/element/attribute/base'

class Form
  module Element
    module Attribute

      class Hash < ::Form::Element::Attribute::Base

        render { content }

        param :attr_prefix, default: nil
        param :attr_path, default: nil
        param :values_type, default: 'text'
        param :label_for_key, default: nil
        param :hidden_keys, default: nil
        param :default_value_for_key, default: nil
        param :allow_remove, default: false

        def init_submission_params
          return super unless mode == "nested_form"
          record.send(attribute_name)&.each do |k, v|
            path_ = path + [k]
            next if form.submission.has_key?(path_)
            form.submission.write_from_db(path_, v)
          end
        end

        def values
          @values ||= form&.submission&.read(path)
        end

        def render_input
          return super if editor == 'hidden'
          layout_input do
            values&.each do |k,v|
              DIV(class: 'd-flex flex-md-row') do
                DIV(class: 'py-2 col-md-4') do
                  label_for_key&.call(k) || k
                end
                DIV(class: 'py-2 flex-fill') do
                  with_remove_button(k, allow_remove) do
                    send("right_column_#{editor || 'input'}", k, v)
                  end
                end
              end
            end
            add_pair_btn
          end
        end

        def with_remove_button(key, allow_remove = true)
          if allow_remove
            DIV(class: 'input-group') do
              yield
              remove_button(key)
            end
          else
            yield
          end
        end

        def remove_button(key)
          A(href: "#remove", class: "btn btn-sm btn-light d-flex align-items-center ml-2") do
            SPAN(class: "fa fa-trash") do
            end
          end.on(:click) do |event|
            event.prevent_default
            remove_value(key)
          end
        end

        def remove_value(key)
          return unless form && !form.reseting?
          values&.delete(key)
          form.enable
          form.submission.write_from_user(path, values)
          change_data(values)
          mutate
          change!(values, form, self)
          form.change
        end

        def right_column_input(k, v)
          INPUT(input_args(k, v)).on(:change) do |event|
            change_value(event.target.value, k)
          end
        end

        def change_value(value, key)
          return unless form && !form.reseting?
          @values ||= {}
          values[key] = value
          form.enable
          form.submission.write_from_user(path, values)
          change_data(values)
          mutate
          change!(values, form, self)
          form.change
        end

        def add_pair_btn
          return unless form && hidden_keys
          hidden_keys_ = hidden_keys.is_a?(Proc) ? hidden_keys&.call(form) : hidden_keys
          AddPairDropDown(hidden_keys: hidden_keys_, label_for_key: label_for_key).on(:select) do |key|
            change_value(default_value_for_key, key)
          end
        end

        class AddPairDropDown < HyperComponent
          param :hidden_keys, default: []
          param :label_for_key, default: nil

          fires :select

          render do
            A(href: "#add_pair", class: "btn btn-light-yiq dropdown-toggle #{'disabled' if hidden_keys.empty?}", "data-toggle": "dropdown") do
              I18n.t('shared.add')
            end
            DIV(class: 'dropdown-menu') do
              hidden_keys.each do |key|
                A(href: '#', class: 'dropdown-item') do
                  label_for_key&.call(key) || key
                end.on(:click) do |event|
                  event.prevent_default
                  select!(key)
                end
              end
            end
          end

        end

        def right_column_enum(k, v)
          Form::Element::Attribute::Enum(
            form: nested_form(k, v),
            prefix_path: ['hash'],
            attribute_name: k,
            possible_values: possible_values
          ).on(:change) do |value, form|
            change_value(value, k)
          end
        end

        def nested_form(k, v)
          @nested_form ||= FakeForm.new
          @nested_form.submission.write(['hash', k], v) unless @nested_form.submission.has_key?(['hash', k])
          return @nested_form
        end

        # read only ------------------------------------------------------

        def read_only_displayed_value
          # form.submission.read(path)
        end

        # nested_form ------------------------------------------------------

        def render_nested_form
          prefix_path_ = prefix_path + [attribute_name]
          sub_record = nil
          children.each do |c|
            if c.props['mode'] == 'nested_form'
              sub_record ||= HyperResource::Base.new(record.send(attribute_name))
              form&.render_child(c, prefix_path_, sub_record, conditions, true)
            else
              form&.render_child(c, prefix_path_, record, conditions, true)
            end
          end
        end

        private

        def input_args(key, value)
          result = {
            value: value,
            type: values_type,
            class: "form-control #{invalid_css_class}",
            id: input_id(key),
          }
          result[:disabled] = "disabled" if disabled_by_autocomplete || disabled
          result[:readonly] = "readonly" if disabled_by_autocomplete || readonly
          result[:"aria-describedby"] = "help-#{form_group_id}" if help.present?
          result[:placeholder] = placeholder if placeholder.present?
          result[:autoFocus] = auto_focus if auto_focus && i == 0
          return result
        end

        def form_group_id(attr_name)
          @form_group_id ||= input_name(attr_name)&.gsub(/\[|\./, '-')&.gsub(']', '')
        end

        def input_id(attr_name)
          "input-#{form_group_id(attr_name)}"
        end

      end
    end
  end
end
