# backtick_javascript: true

class Form
  module Element
    module Attribute
      class Text < ::Form::Element::Attribute::Base

        TINYMCE_SETTINGS =  {
          init: {
            skin: false,
            content_css: false,
            inline: true,
            branding: false,
            statusbar: false,
            urlconverter_callback: `(url, node, on_save, name) => {
              return url;
            }`,
            setup: `(editor) => {
              const element = editor.getElement();
              if (element && element.offsetWidth > 0) {
                editor.settings.max_width = element.offsetWidth;
              }
            }`,
            plugins: [
              'advlist',
              'anchor',
              'autolink',
              'autoresize',
              'autosave',
              #'bbcode',
              'charmap',
              'code',
              #'codesample',
              'directionality',
              #'emoticons',
              #'fullpage',
              'fullscreen',
              #'help',
              'hr',
              'image',
              'imagetools',
              #'importcss',
              'insertdatetime',
              #'legacyoutput',
              'link',
              'lists',
              'media',
              'nonbreaking',
              'noneditable',
              #'pagebreak',
              'paste',
              #'preview',
              #'print',
              'quickbars',
              #'save',
              'searchreplace',
              #'spellchecker',
              'tabfocus',
              'table',
              'template',
              'textpattern',
              'toc',
              'visualblocks',
              'visualchars',
              'wordcount'
            ],
            menu: {
              edit: { title: 'Edit', items: 'undo redo | cut copy paste | selectall | searchreplace' },
              insert: { title: 'Insert', items: 'image link media inserttable | charmap emoticons hr | nonbreaking anchor toc | insertdatetime' },
              format: { title: 'Format', items: 'bold italic underline strikethrough superscript subscript codeformat | formats blockformats fontformats fontsizes align | forecolor backcolor | removeformat' },
              table: { title: 'Table', items: 'inserttable | cell row column | tableprops deletetable' },
              tools: { title: 'Tools', items: 'code wordcount' },
            },
            toolbar: 'bold italic underline strikethrough | forecolor backcolor removeformat | fontsizeselect formatselect | alignleft aligncenter alignright alignjustify | numlist bullist | | charmap emoticons | fullscreen | insertfile image imagetools media link anchor | ltr rtl',
            menubar: 'edit insert format table tools',
            #menu: {
              #file: { title: 'File', items: 'preview | print ' },
              #edit: { title: 'Edit', items: 'undo redo | cut copy paste | selectall | searchreplace' },
              #view: { title: 'View', items: 'code | visualaid visualchars visualblocks | spellchecker | preview fullscreen' },
              #insert: { title: 'Insert', items: 'image link media template codesample inserttable | charmap emoticons hr | pagebreak nonbreaking anchor toc | insertdatetime' },
              #format: { title: 'Format', items: 'bold italic underline strikethrough superscript subscript codeformat | formats blockformats fontformats fontsizes align | forecolor backcolor | removeformat' },
              #tools: { title: 'Tools', items: 'code wordcount spellchecker spellcheckerlanguage | code wordcount' },
              #table: { title: 'Table', items: 'inserttable | cell row column | tableprops deletetable' },
              #help: { title: 'Help', items: 'help' }
            #},
            #toolbar: 'bold italic underline strikethrough | forecolor backcolor removeformat | fontsizeselect formatselect | alignleft aligncenter alignright alignjustify | numlist bullist | pagebreak | charmap emoticons | fullscreen  preview save print | insertfile image media template link anchor codesample | ltr rtl',
          }.to_n
        }.freeze

        render { content }

        after_mount do
          add_error_css_class
        end

        after_update do
          add_error_css_class
        end

        FORMAT_EDITORS = {
          'raw' => 'textarea',
          'rich' => 'tinymce',
        }.freeze

        def default_editor
          FORMAT_EDITORS[attribute_format] || 'tinymce'
        end

        def render_input
          send("render_input_#{editor || default_editor}")
        end

        def render_edit_in_place_editing
          send("render_edit_in_place_#{editor || default_editor}_editing")
        end

        # Tiny MCE ------------------------------------------------------------

        def render_input_tinymce
          layout_input do
            TinyMCE(tinymce_args).on(:init) do |event, editor|
              add_editor_style(editor)
            end.on(:editor_change) do |content, editor|
              change_value(content)
            end
            input_errors
          end
        end

        def tinymce_args
          {
            id: input_id,
            value:  form.submission.read(path).to_s,
            init: tinymce_args_init,
          }
        end

        def tinymce_args_init
          init = TINYMCE_SETTINGS[:init]
          ::Hash.new(init).merge!({
            inline: other_params.has_key?(:tinymce_inline) ? other_params[:tinymce_inline] : true,
            language: I18n.locale == 'fr' ? 'fr_FR' : 'en',
            placeholder: placeholder_,
            readonly: readonly, # doesn't work ?
            auto_focus: auto_focus ? input_id : '',
          }).to_n
        end

        def add_error_css_class
          ::Element.find('#' + input_id).toggle_class('is-invalid', !!record_is_invalid?)
        end

        def add_editor_style(editor)
          element = ::Element.find('#' + editor.id)
          element.css('height', 'initial');
          element.add_class('form-control') # editor.id should be equal to input_id
          element.attr('disabled', 'disabled') if disabled_by_autocomplete || disabled
          element.attr("aria-describedby", "help-#{form_group_id}") if help.present?
        end

        # Textarea ------------------------------------------------------

        def render_input_textarea
          layout_input do
            TEXTAREA(input_args).on(:change) do |event|
              change_value(event.target.value)
            end
            input_errors
          end
        end


        # Edit in place -------------------------------------------------


        def edit_in_place_fake_input
          DIV(class: "form-control #{css_classes&.dig(:field_size)} px-0 cursor-text bg-transparent", style:{ height: '100%' }) do
            yield
            edit_in_place_icon
          end
        end

        def edit_in_place_value_container
          DIV(dangerously_set_inner_HTML: { __html: yield }, style: {maxHeight: '400px', overflow: 'hidden'})
        end

        # Textarea ------------------------------------------------------
        def render_edit_in_place_textarea_editing
          TEXTAREA(input_args).on(:change) do |event|
            change_value(event.target.value)
          end.on(:focus) do |event|
            @original_value = event.target.value
            event.target.select
          end.on(:blur) do |event|
            edit_in_place_submit_value(event.target.value)
          end.on(:key_up) do |event|
            case event.key_code
            when 13 # enter
              edit_in_place_submit_value(event.target.value)
            when 27 # escape
              form.submission.write_from_db(path, @original_value) # TODO use submission.restore
              @edit = false
              form.cancel!
              mutate
            end
          end
        end

        # Tiny MCE ------------------------------------------------------------
        def render_edit_in_place_tinymce_editing
          TinyMCE(tinymce_edit_in_place_args).on(:init) do |event, editor|
            add_editor_style(editor)
          end.on(:editor_change) do |content, editor|
            change_value(content)
          end.on(:focus) do
            @original_value = form.submission.read(path)
          end.on(:blur) do |event, editor|
            value = form.submission.read(path)
            edit_in_place_submit_value(value)
          end
        end

        def tinymce_edit_in_place_args
          result = {
            id: input_id,
            value:  form.submission.read(path).to_s,
          }
          result[:init] = ::Hash.new(TINYMCE_SETTINGS[:init]).merge!({
            language: I18n.locale == 'fr' ? 'fr_FR' : 'en',
            auto_focus: input_id,
          }).to_n
          return result
        end

        def focus_edit_in_place_editing_input
          # do nothing
        end

        def read_only_value_container
          edit_in_place_value_container do
            yield
          end
        end

        # Smsarea ------------------------------------------------------

        def render_input_smsarea
          @characters_left_for_sms = 160 unless @characters_left_for_sms.present?
          @sms_count = 1 unless @sms_count

          layout_input do
            TEXTAREA(input_args).on(:change) do |event|
              @message = event.target.value
              with_delay(0.5) do
                assign_sms_count_infos(@message)
                mutate
              end
              change_value(event.target.value)
            end

            P(class: 'pt-1 pr-1 mb-0 text-right') do
              "#{@characters_left_for_sms} #{I18n.t('sequence.character')} / #{@sms_count} SMS"
            end
            input_errors
          end
        end

        def with_delay(duration = 0.2, want_instant_pass = false)
          if !@doing && want_instant_pass
            @doing = true
            yield
          else
            @delay&.abort
            @delay = after!(duration) do
              yield
            end
            @delay.start
          end
        end

        def assign_sms_count_infos(sms)
          sms_format_infos = `splitSms(#{sms})`
          @sms_count = `#{sms_format_infos}.parts.length`
          @characters_left_for_sms = `#{sms_format_infos}.remainingInPart`
        end

      end
    end
  end
end
