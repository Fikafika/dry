# backtick_javascript: true

require 'components/form/element/attribute/base'

class Form
  module Element
    module Attribute

      class String < ::Form::Element::Attribute::Base
        include Hyperstack::Router::Helpers
        include Protocol::DropdownItem
        include Protocol::Helpers

        render { content }

        FORMAT_EDITORS = {
          'phone' => 'tel',
          'qrcode' => 'qrcode',
        }.freeze

        def default_editor
          return attribute_editor if attribute_editor == 'autocomplete' && mode == 'input'
          FORMAT_EDITORS[attribute_format] || super
        end

        def render_input_formula_editor
          unless ENV['FORMULA_EDITOR_PATH'].present? && other_params[:lsp_url].present?
            return render_input_textarea(style: {height: ::FormulaEditor::DEFAULT_HEIGHT}) # same height as formula_editor
          end
          layout_input do
            FormulaEditor(
              name: 'formula_' + form_group_id,
              lsp_url: other_params[:lsp_url],
              value: form&.submission&.read(path),
              height: other_params[:height],
            ).on(:change) do |v|
              change_value(v)
            end
            DIV(class: "d-none form-control #{invalid_css_class}") # to display invalid-feedback with bootstrap
            input_errors
          end
        end

        # QR Code ------------------------------------------------------------------

        def render_input_qrcode
          render_input_text
        end

        def render_edit_in_place_not_editing_qrcode
          edit_in_place_fake_input_qrcode do
            edit_in_place_value_container do
              if empty_and_show_placeholder?
                placeholder
              else
                value = form&.submission&.read(path)
                IMG(src: qrcode(value), class: "qr-code") if value.present?
              end
            end
          end.on(:click) do |event|
            next if ::Element[event.target.to_n].closest('a').length > 0
            event.prevent_default
            @edit = true
            mutate
          end
        end

        def render_edit_in_place_not_editing
          try("render_edit_in_place_not_editing_#{editor || default_editor}") || super
        end

        def edit_in_place_fake_input_qrcode
          DIV(class: 'form-control px-0 bg-transparent cursor-pointer h-100') do
            yield
            edit_in_place_icon
          end
        end

        def edit_in_place_fake_input
          m = :"edit_in_place_fake_input_#{editor || default_editor}"
          respond_to?(m) ? send(m) : super
        end

        def render_edit_in_place_editing
          m = :"render_edit_in_place_editing_#{editor || default_editor}"
          respond_to?(m) ? send(m) : super
        end

        def qrcode(str)
          result = nil;
          `QRCode.toDataURL(#{str&.to_n}, { margin: 0 }, (err, url) => { #{result} = url; })`
          return result
        end

        # diff ------------------------------------------------------------------

        def render_diff
          layout_diff do
            SPAN(class: "diff #{(value_was != value) ? 'add' : '' }") do
              value # displayed_value ?
            end
            if value_was.present? && value_was != value
              SPAN(class: 'diff remove') do
                value_was
              end
            end
          end
        end

        def edit_in_place_displayed_value
          render_value(truncate: true)
        end

        def render_value(truncate: false)
          value = form&.submission&.read(path)&.to_s
          if has_protocols?
            render_link(value)
          elsif render_edit_record_link?
            render_edit_record_link
          elsif truncate
            SPAN(class: 'text-truncate d-block', title: value) { value }
          else
            value
          end
        end

        # read_only -----------------------------------------------------------

        def read_only_displayed_value
          render_value(truncate: false)
        end

        def render_edit_record_link?
          attribute_name == record_klass.try(:name_attribute) && form&.other_params[:render_edit_record_links] != false
        end

        def render_link(value)
          return value unless has_protocols?
          protocols = record_klass.protocols_for_attributes[attribute_name.to_sym]
          prefered_protocol = protocols.first
          DIV(class: 'input-group text-truncate') do
            prepend_protocol_dropdown(protocols, prefered_protocol, value) if protocols.count > 1
            href = "#{formated_protocol(prefered_protocol)}#{value}"
            A(href: href, class: 'text-truncate', title: value, **link_target_attributes(prefered_protocol)) do
              value
            end.on(:click) do |event|
              # hypertext links open in a new tab, like in the datatable
              next unless prefered_protocol == 'http'
              event.prevent_default
              event.stop_propagation
              `window.open(#{href}, '_blank', 'noopener,noreferrer')`
            end
          end
        end

        def render_edit_record_link
          value = form&.submission&.read(path)&.to_s
          Link(url_for(record: record, action: 'edit'), {'data-open-panel' => 'opposite', class: 'text-truncate d-block', title: value}) do
            value
          end.on(:click) do |event|
            event.stop_propagation
          end
        end

        def render_edit_in_place_editing
          return super unless (editor || default_editor) == 'tel' # TODO by calling this method render_edit_in_place_editing_tel, we should be able to get rid of this line

          @parse_number_in_editing = parse_number(form&.submission&.read(path))
          @alpha2_in_editing = @parse_number_in_editing&.country&.downcase
          @country_calling_code_in_editing = @parse_number_in_editing&.countryCallingCode
          @alpha2 = @alpha2_in_editing if @alpha2_in_editing

          layout_input_tel() do
            input_tel_edit_in_place
          end
        end

        def input_tel_edit_in_place
          INPUT(input_args)
          .on(:change) do |event|
            change_input_tel_value(event.target.value)
          end.on(:focus) do |event|
            @original_value = form&.submission&.read(path)
            mutate
          end.on(:blur) do |event|
            validate_input_tel_on_blur
            unless ::Element[event.related_target.to_n].has_class?('dropdown-toggle') # unless click in dropdown
              edit_in_place_submit_value(event.target.value)
            end
          end.on(:key_up) do |event|
            case event.key_code
            when 13 # enter
              edit_in_place_submit_value(event.target.value)
            when 27 # escape
              form.submission.write_from_db(path, @original_value) # TODO use submission.restore
              @edit = false
              mutate
            end
          end
        end

        def change_input_tel_value(str)
          @parsed_number = parse_number_with_local_alternative(str, @alpha2&.upcase)

          @number =  @parsed_number&.is_valid ? @parsed_number.number : str
          @country = @parsed_number&.country&.downcase
          @country_calling_code = @parsed_number&.countryCallingCode
          @alpha2 = @country if @country
          @prefix_telephone = "+" + @country_calling_code if @country_calling_code

          if @parsed_number&.is_valid && @valid == false
            @valid = @parsed_number.is_valid
          end

          change_value(@number) if @number
        end

        def validate_input_tel_on_blur
          if @parsed_number && @valid != @parsed_number.is_valid
            mutate @valid = @parsed_number.is_valid
          end
        end

        def render_input_tel
          layout_input do
            layout_input_tel() do
              input_tel()
            end
            input_errors
          end
        end

        def layout_input_tel
          DIV(class: "input-group mb-3") do
            DIV(class: "input-group-prepend") do
              FlagDropdown(alpha2: @alpha2).on(:click) do |alpha2|
                @alpha2 = alpha2
                if @country_calling_code_in_editing
                  @previous_prefix = "+" + @country_calling_code_in_editing
                else
                  @previous_prefix = @prefix_telephone
                end

                @prefix_telephone = I18n.t("phone_prefix.#{alpha2}")

                if (form.submission.read(path) != "" && !@number.nil?) || @country_calling_code_in_editing
                  @number_after_prefix_change = form&.submission&.read(path)&.sub(@previous_prefix, @prefix_telephone)
                  change_value(@number_after_prefix_change)
                else
                  change_value(@prefix_telephone)
                end
                ::Element.find(dom_node).find('input.form-control').focus
                mutate
              end
            end
            if !@alpha2
              @alpha2 = "fr"
              @prefix_telephone = "+33"
              mutate
            end
            yield
          end
        end

        def input_tel
          INPUT(input_args)
          .on(:change) do |event|
            change_input_tel_value(event.target.value)
          end.on(:blur) do
            validate_input_tel_on_blur
          end
        end

        class FlagDropdown < HyperComponent

          param :alpha2

          fires :click

          render do
            button_prefix_tel
            dropdown
          end

          def button_prefix_tel
            BUTTON(
              name: "btn_dropdown_countries",
              type: "button",
              class: "input-group-text btn btn-light dropdown-toggle d-flex align-items-center",
              "data-toggle": "dropdown",
              "aria-haspopup": "true",
              "aria-expanded": "false"
            ) do
              if alpha2
                DIV(class: "pr-2") { I18n.t("flags.#{alpha2}") }
              else
                DIV(class: "pr-2 opacity-0"){ I18n.t("flags.fr") }
              end
            end.on(:click) do
              mutate @render_dropdown_list = true
            end
          end

          def dropdown
            DIV(class: "dropdown-menu") do
              DIV(class: 'px-2') do
                INPUT(
                  class: 'form-control',
                  placeholder: I18n.t('shared.search'),
                  value: @query,
                ).on(:change) do |event|
                  @query = event.target.value
                  mutate
                end
              end
              DIV(class: "dropdown-divider mb-0", role: "separator"){}
              DIV(
                class: 'drop',
                style: {
                  overflowY: "scroll",
                  maxHeight: '50vh',
                }
              ) do
                @render_dropdown_list ? dropdown_list : dropdown_list_placeholder
              end
            end
          end

          def dropdown_list
            filrer_countries.map do |k, v|
              BUTTON(
                class: "dropdown-item d-flex #{alpha2 == k && "active"}",
                name: v
              ) do
                DIV(class: "pr-3") { k ? I18n.t("flags.#{k}") : "" }
                DIV(class: "pr-2"){v}
                DIV{I18n.t("phone_prefix.#{k}")}
              end.on(:click) do
                @query = nil
                click!(k)
              end
            end
          end

          def filrer_countries
            @sorted_countries ||= ::Hash.new(`I18n.translations[#{I18n.locale}]['countries']`).sort_by {|k, v| v}
            if @query.present?
              filtered_countries = @sorted_countries.select do |k, v|
                v.downcase.include?(@query ? @query.downcase : "") || I18n.t("phone_prefix.#{k}").include?(@query ? @query.downcase : "")
              end
            else
              filtered_countries = @sorted_countries
            end
          end

          def dropdown_list_placeholder
            DIV(style: {minHeight: '50vh'}) do
            end
          end
        end

        def parse_number_with_local_alternative(str, default_country)
          alt = find_alternative_countries(default_country, str)
          r = nil
          alt.each do |a|
            r = parse_number(str, a)
            break if r&.is_valid
          end
          return r if r
          return parse_number(str, default_country)
        end

        def find_alternative_countries(alpha2, str)
          las = local_alternatives[alpha2]
          return [] unless las
          result = nil
          local_without_prefix = str.gsub(/\s|\./, '').sub(/^0/, '')
          result = []
          las.each do |reg, a|
            result << a if local_without_prefix =~ reg
          end
          return result
        end

        def local_alternatives
          return @local_alternatives if @local_alternatives

          @local_alternatives = {}

          jumps = {
            'FR' => ['GP', 'PM', 'MQ', 'RE', 'GF', 'YT']
          }

          # extracted from Phonelib with
          # r = {}
          # (jumps.values.flatten + jumps.keys).uniq.each do |a|
          #   r[a] = [
          #     Phonelib.phone_data[a][:types][:fixed_line][:national_number_pattern],
          #     Phonelib.phone_data[a][:types][:mobile][:national_number_pattern],
          #   ]
          # end

          regs = {
            'GP' => [
              '590(?:0[1-68]|[14][0-24-9]|2[0-68]|3[1-9]|5[3-579]|[68][0-689]|7[08]|9\\d)\\d{4}',
              '69(?:0\\d\\d|1(?:2[2-9]|3[0-5])|4(?:0[89]|1[2-6]|9\\d)|6(?:1[016-9]|5[0-4]|[67]\\d))\\d{4}'
            ],
            'PM' => [
              '(?:4[1-35-7]|5[01])\\d{4}',
              '(?:4[02-4]|5[056]|708[45][0-5])\\d{4}'
            ],
            'MQ' => [
              '596(?:[03-7]\\d|1[05]|2[7-9]|8[0-39]|9[04-9])\\d{4}',
              '69(?:6(?:[0-46-9]\\d|5[0-6])|727)\\d{4}'
            ],
            'RE' => [
              '26(?:2\\d\\d|3(?:0\\d|1[0-6]))\\d{4}',
              '69(?:2\\d\\d|3(?:[06][0-6]|1[013]|2[0-2]|3[0-39]|4\\d|5[0-5]|7[0-37]|8[0-8]|9[0-479]))\\d{4}'
            ],
            'GF' => [
              '594(?:[02-49]\\d|1[0-5]|5[6-9]|6[0-3]|80)\\d{4}',
              '694(?:[0-249]\\d|3[0-8])\\d{4}'
            ],
            'YT' => [
              '269(?:0[0-467]|15|5[0-4]|6\\d|[78]0)\\d{4}',
              '639(?:0[0-79]|1[019]|[267]\\d|3[09]|40|5[05-9]|9[04-79])\\d{4}'
            ],
            'FR' => [
              '(?:26[013-9]|59[1-35-9])\\d{6}|(?:[13]\\d|2[0-57-9]|4[1-9]|5[0-8])\\d{7}',
              '(?:6(?:[0-24-8]\\d|3[0-8]|9[589])|7[3-9]\\d)\\d{6}'
            ]
          }

          regs.each do |k, v|
            regs[k] = v.map{|r| Regexp.new("^#{r}$") }
          end

          jumps.each do |c, alts|
            @local_alternatives[c] ||= {}
            alts.each do |a|
              regs[a].each do |r|
                @local_alternatives[c][r] = a
                regs[c]&.each do |r2|
                  @local_alternatives[a] ||= {}
                  @local_alternatives[a][r2] = c
                end
              end
            end
          end

          return @local_alternatives
        end

        def parse_number(str, default_country)
          return unless str.present?
          r = `parsePhoneNumber(#{str.to_s}, {defaultCountry: #{default_country}})`
          if r
            `#{r}.is_valid = #{r}.isValid()`
          else
            r = `{is_valid: false}`
          end
          return Native::Object.new(r || `{}`)
        end

        def has_protocols?
          record_klass.respond_to?(:protocols_for_attributes) && record_klass.protocols_for_attributes[attribute_name.to_sym].present?
        end

        def prepend_protocol_dropdown(protocols, prefered_protocol, value)
          additional_params = {
            class: 'dropdown-item'
          }.merge(record_data_for_link(record_klass.to_s, record.id))
          DIV(class: 'input-group-preprend pr-2') do
            A(href: "#", class: 'btn btn-sm btn-transparent-light py-0 rounded-left dropdown-toggle', 'data-toggle': 'dropdown', 'aria-haspopup': 'true', 'aria-expanded': 'false') do
              I(class: "fas fa-#{I18n.t("icons.protocols.#{prefered_protocol}")} fa-fw pr-3") {}
            end
            DIV(class: 'dropdown-menu scrollable-menu') do
              protocols.each do |protocol|
                dropdown_item_for_protocol(protocol, value, additional_params)
              end
            end
          end
        end

        def invalid_css_class
          if record_is_invalid?
            ' is-invalid'
          else
            if @valid.nil? || @valid
              ''
            else
              ' is-invalid'
            end
          end
        end
      end
    end
  end
end
