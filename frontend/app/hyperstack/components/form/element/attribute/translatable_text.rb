# backtick_javascript: true

require 'components/form/element/attribute/translatable'
require 'components/form/element/attribute/text'

class Form
  module Element
    module Attribute
      class TranslatableText < ::Form::Element::Attribute::Translatable
        render { content }

        before_mount do
          @locale ||= I18n.locale
        end

        before_update do
          @locale ||= I18n.locale
        end

        after_mount do
          add_error_css_class
        end

        after_update do
          add_error_css_class
        end

        def render_input
          layout_globalize_inputs do
            for_each_locale do |locale, i|
              layout_globalize_input(i) do
                TinyMCE(tinymce_args).on(:init) do |event, editor|
                  add_editor_style(editor)
                end.on(:editor_change) do |content, editor|
                  change_value(content, locale)
                end
                locale_btn(locale, i)
                input_errors
              end
            end
          end
        end

        def locale_btn(locale, i)
          DIV(class: "d-flex") do
            DIV(class: 'flex-grow-1') {}
            DIV class: "input-group-text rounded-bottom border-top-0 #{'cursor-pointer' if compact?}", style: {borderTopRightRadius: 0, borderTopLeftRadius: 0} do
              SPAN(class: 'pr-1') do
                FLAGS[locale]
              end
              I(class: "fa fa-chevron-right fa-fw fa-rotate-#{@opened ? 270 : 90} fa-xs") do
              end
            end
          end.on(:click) do
            if compact?
              @opened = !@opened
              mutate
            end
          end
        end

        def tinymce_args
          {
            id: input_id,
            value: form.submission.read(path).to_s,
            init: tinymce_args_init
          }
        end

        def tinymce_args_init
          init = ::Form::Element::Attribute::Text::TINYMCE_SETTINGS[:init]
          ::Hash.new(init).merge!({
            inline: other_params.has_key?(:tinymce_inline) ? other_params[:tinymce_inline] : true,
            language: I18n.locale == 'fr' ? 'fr_FR' : 'en',
            placeholder: placeholder,
            readonly: readonly, # doesn't work ?
            auto_focus: auto_focus ? input_id : '',
          }).to_n
        end

        def add_error_css_class
          ::Element.find('#' + input_id).toggle_class('is-invalid', record_is_invalid?)
        end

        def add_editor_style(editor)
          element = ::Element.find('#' + editor.id)
          element.css('height', 'initial')
          element.css('transition', 'none')
          element.add_class('form-control') # editor.id should be equal to input_id
          element.attr('disabled', 'disabled') if disabled_by_autocomplete || disabled
          element.attr("aria-describedby", "help-#{form_group_id}") if help.present?
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

            DIV(class: "#{input_col_size}") do
              SMALL(id: "help-#{localized_form_group_id}", class: "help-block", dangerously_set_inner_HTML: { __html: help }) if i == 0 && help.present?
              yield
            end
          end
        end

        # edit in place ----------------------------------------------------------------

        def edit_in_place_fake_input
          DIV(class: "form-control #{css_classes&.dig(:field_size)} px-0 cursor-text bg-transparent", style:{ height: '100%' }) do
            yield
            edit_in_place_icon
          end
        end

        def edit_in_place_value_container
          DIV(dangerously_set_inner_HTML: { __html: yield }, style: {maxHeight: '400px', overflow: 'hidden'})
        end

        def render_edit_in_place_editing
          TinyMCE(tinymce_edit_in_place_args).on(:init) do |event, editor|
            add_editor_style(editor)
          end.on(:editor_change) do |content, editor|
            change_value(content)
          end.on(:focus) do
            @original_value = form.submission.read(path)
            `$(window).trigger('resize')`
          end.on(:blur) do |event, editor|
            value = form.submission.read(path)
            edit_in_place_submit_value(value)
          end
        end

        def tinymce_edit_in_place_args
          result = {
            id: input_id,
            value: form.submission.read(path).to_s,
          }
          result[:init] = ::Hash.new(::Form::Element::Attribute::Text::TINYMCE_SETTINGS[:init]).merge!({
            language: I18n.locale == 'fr' ? 'fr_FR' : 'en',
            auto_focus: input_id,
          }).to_n
          return result
        end

        def focus_edit_in_place_editing_input
          # do nothing
        end

        def edit_in_place_submit_value(value)
          if @original_value != value
            @loading = true
            @success = nil
            record.update(localized_attribute_name => value).then do |response|
              @success = response[:success]
              @loading = false
              mutate
            end
          end
          @edit = false
          mutate
        end

        # read only ------------------------------------------------------

        def read_only_value_container
          edit_in_place_value_container do
            yield
          end
        end

      end
    end
  end
end
