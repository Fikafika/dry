require 'components/form/element/attribute/translatable'

class Form
  module Element
    module Attribute

      class TranslatableString < ::Form::Element::Attribute::Translatable
        include Hyperstack::Router::Helpers

        render { content }

        def render_input
          layout_globalize_inputs do
            for_each_locale do |locale, i|
              layout_globalize_input(i) do
                INPUT(input_args(i)).on(:change) do |event|
                  change_value(event.target.value, locale)
                end
                locale_btn(locale, i)
                input_errors
              end
            end
          end
        end

        def locale_btn(locale, i)
          DIV class: "input-group-append #{'cursor-pointer' if compact?} d-block" do
            SPAN class: 'input-group-text' do
              if compact?
                SPAN(class: 'pr-1') do
                  FLAGS[locale]
                end
                I(class: "fa fa-chevron-right fa-fw fa-rotate-#{@opened ? 270 : 90} fa-xs") do
                end
              else
                FLAGS[locale]
              end
            end
          end.on(:click) do
            if compact?
              @opened = !@opened
              mutate
            end
          end
        end

        # read only ------------------------------------------------------

        def read_only_displayed_value
          if render_edit_record_link?
            render_edit_record_link
          else
            form&.submission&.read(path)&.to_s
          end
        end

        def render_edit_record_link?
          attribute_name == record_klass.try(:name_attribute) && form&.other_params[:render_edit_record_links] != false
        end

        def render_edit_record_link
          value = form&.submission&.read(path)&.to_s
          Link(url_for(record: record, action: 'edit'), {'data-open-panel' => 'opposite'}) do
            value
          end.on(:click) do |event|
            event.stop_propagation
          end
        end

        private

        def input_args(i)
          result = {
            name: input_name,
            value: form.submission.read(path),
            type: 'text',
            class: "form-control #{invalid_css_class}",
            id: input_id,
          }
          result[:disabled] = "disabled" if disabled_by_autocomplete || disabled
          result[:readonly] = "readonly" if disabled_by_autocomplete || readonly
          result[:"aria-describedby"] = "help-#{form_group_id}" if help.present?
          result[:placeholder] = localized_placeholder if localized_placeholder.present?
          result[:autoFocus] = auto_focus if auto_focus && i == 0
          return result
        end

        def layout_globalize_input(i)
          visible = !compact? || i == 0 || @opened
          DIV(id: localized_form_group_id, class: "row form-group #{requirement} #{'d-none' unless visible}") do
            if show_label
              if i == 0
                LABEL(class: "#{label_col_size} control-label #{css_classes&.dig(:label_size)}", htmlFor: input_id) do
                  label || record&.class&.human_attribute_name(attribute_name)
                end
              else
                DIV(class: label_col_size) {}
              end
            end

            DIV(class: input_col_size) do
              DIV(class: "input-group") do
                yield
              end
              SMALL(id: "help-#{localized_form_group_id}", class: "form-text", dangerously_set_inner_HTML: { __html: help }) if i == 0 && help.present?
            end
          end
        end

      end
    end
  end
end
