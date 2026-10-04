require 'components/form/element/base'
require 'uneek_formatting'

class Form
  module Element
    module Attribute

      class Base < ::Form::Element::Base
        include UneekFormatting::Dynamic::AttributeFormatter

        render { content }

        # input ------------------------------------------------------------------

        def render_input
          has_api? ? send("render_input_autocomplete") : send("render_input_#{editor || default_editor}")
        end

        def default_editor
          'text'
        end

        def attribute_format
          record_klass.try(:attribute_format, attribute_name)
        end

        def attribute_editor
          record_klass.try(:attribute_editor, attribute_name)
        end

        def render_input_text
          layout_input do
            INPUT(input_args).on(:change) do |event|
              change_value(event.target.value)
            end
            input_errors
          end
        end

        def input_args
          result = {
            id: input_id,
            name: input_name,
            value: form&.submission&.read(path),
            type: 'text',
            class: "form-control #{invalid_css_class} #{input_class}",
          }
          result[:disabled] = "disabled" if disabled_by_autocomplete || disabled
          result[:readOnly] = "readonly" if disabled_by_autocomplete || readonly
          result[:"aria-describedby"] = "help-#{form_group_id}" if help.present?
          p = placeholder_
          result[:placeholder] = p if p
          result[:autoFocus] = auto_focus if auto_focus
          return result
        end

        def render_input_textarea(additional_input_args = {})
          layout_input do
            TEXTAREA(input_args.deep_merge(additional_input_args)).on(:change) do |event|
              change_value(event.target.value)
            end
            input_errors
          end
        end

        def has_api?
          record_klass.try(:api_data)&.has_key?(attribute_name)
        end

        def schema_klass
          observe @schema_klass = Dynamic::Schema::Klass.includes({attrs: {includes: {translations: 1}}}).where(schema_id: form.other_params[:schema_id]).find(prefix_path[0])
        end

        def render_input_autocomplete
          layout_input do
            InputWithAutocomplete(input_with_autocomplete_args).on(:select) do |event, item|
              autocomplete_clear_elements if autocomplete_clear_elements?
              autocomplete_disable_elements if autocomplete_disable_elements?(event)
              change_values(*convert_record_hash_to_values(item['record']))
            end.on(:change) do |event|
              autocomplete_enable_elements if autocomplete_enable_elements?(event)
              change_value(event.target.value)
            end
            input_errors
          end
        end

        def input_with_autocomplete_args
          {
            input_args: input_args,
            search_url: api_data[:url],
            process_params: Proc.new{ |params| add_autocomplete_filters_to_params(params) },
            term_param: api_data[:term_param],
            http_options: api_data[:http_options],
            process_results: api_data[:process_results],
            convert_selected_item: api_data[:convert_selected_item],
          }
        end

        def api_data
          @api_data ||= record_klass.try(:api_data).try(:[], attribute_name) || backend_api_data
        end

        def determine_autocomplete_variable_values
          @variables ||= extract_variables(autocomplete_filters_result)
          return unless @variables.any?

          result = {}
          @variables.each do |v|
            path = build_path(form.prefix_path + v.split('.'))
            value = form.submission.read(path)
            if other_params[:convert_autocomplete_variable]
              value = other_params[:convert_autocomplete_variable].call(v, value)
            end
            result[v] = value
          end
          return result
        end

        def build_path(variable_path)
          result = []
          variable_path.each_with_index do |attr, i|
            result << 0 if i > 0
            result << attr.delete('[]')
          end
          return result
        end

        def backend_api_data
          {
            url: record_klass&.collection_path(params_for_autocomplete),
            term_param: 'term',
            http_options: {},
            process_params: Proc.new{ |params| add_autocomplete_filters_to_params(params) },
            convert_selected_item: Proc.new do |item, &block|
              record_id = item['id']
              record_klass = self.record_klass || item.dig('record', 'type')&.safe_constantize
              if record_klass
                params = {id: record_id}
                includes = form&.dynamic_form&.autocomplete_includes(self.prefix_path) || other_params[:autocomplete_includes]
                params.merge!(includes) if includes
                ::HttpWithCrossDomain.get(record_klass.member_path(params)).then do |response|
                  item['record'] = response.json
                  block.call(item)
                end
              end
            end,
            disable_elements: true,
            fill_not_in_form_fields: true,
          }
        end

        def autocomplete_api_of_selected_item # TODO
          api_data
        end

        def params_for_autocomplete
          return other_params[:params_for_autocomplete] if other_params[:params_for_autocomplete]
          return request ? request.params.to_h.except('_', 'rp') : {} # TODO improve
        end

        def autocomplete_disable_elements
          form.submission.disable(prefix_path)
        end

        def autocomplete_disable_elements?(event)
          autocomplete_api_of_selected_item[:disable_elements]
        end

        def autocomplete_clear_elements
          form.submission.delete(prefix_path, form.association_min)
        end

        def autocomplete_clear_elements?
          true # TODO
        end

        def autocomplete_enable_elements
          form.submission.enable(prefix_path)
          form.submission.delete(prefix_path, form.association_min)
          form.mutate
        end

        def autocomplete_enable_elements?(event)
          autocomplete_disable_elements?(event) && form&.submission && form.submission.disabled[prefix_path]
        end

        def filled_by_autocomplete?(path)
          autocomplete_api_of_selected_item[:fill_not_in_form_fields] || form.submission.values.has_key?(path)
        end

        def convert_record_hash_to_values(record_hash, prefix_path = self.prefix_path, values_result = [], data_result = {}, from = :user)
          record_hash&.each do |k, v|
            path = prefix_path + [k]
            case v
            when ::Array
              if filled_by_autocomplete?(path)
                records = v.map do |e|
                  (e[:type]&.safe_constantize || HyperResource::Base).polymorphic_new(e.deep_dup)
                end
                data_result[path] = HyperResource::Relation.new(nil, records: records)
              end
              v.each_with_index do |e, i|
                convert_record_hash_to_values(e, prefix_path + [k, i], values_result, data_result, :db)
              end
            when ::Hash
              if v[:attachment]&.any?
                if filled_by_autocomplete?(path)
                  attached = ::HyperResource::ActiveStorage::Attached::One.new(v[:name], nil, v)
                  values_result << {path: path, value: attached.signed_id, from: :db}
                  data_result[path] = attached
                end
              elsif v[:attachments]
                if filled_by_autocomplete?(path)
                  attached = ::HyperResource::ActiveStorage::Attached::Many.new(v[:name], nil, v)
                  values_result << {path: path, value: attached.attachments&.map(&:signed_id), from: :db}
                  data_result[path] = attached.attachments
                end
              else
                if filled_by_autocomplete?(path)
                  values_result << {path: path, value: v, from: :db}
                  data_result[path] = (v[:type]&.safe_constantize || HyperResource::Base).polymorphic_new(v)
                end
                convert_record_hash_to_values(v, prefix_path + [k, 0], values_result, data_result, from)
              end
            else
              if filled_by_autocomplete?(path)
                from_ = (from == :user && ['id', 'type'].include?(k)) ? :user : :db
                values_result << {path: path, value: v, from: from_}
              end
            end
          end
          return values_result, data_result
        end

        # edit in place -----------------------------------------------------------

        after_mount do
          focus_edit_in_place_editing_input if edit_in_place_editing? || form&.mode == :edit_cell
        end

        after_update do
          focus_edit_in_place_editing_input if edit_changed? && edit_in_place_editing?
        end

        def render_edit_in_place
          layout_edit_in_place do
            if edit_in_place_editing?
              if has_api?
                render_edit_in_place_editing_with_autocomplete
              else
                render_edit_in_place_editing
              end
            else
              render_edit_in_place_not_editing
            end
          end
        end

        def render_edit_in_place_editing
          INPUT(input_args).on(:change) do |event|
            change_value(event.target.value)
          end.on(:focus) do |event|
            @original_value = edit_in_place_original_value(event)
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

        def edit_in_place_original_value(event)
          event.target.value
        end

        def edit_in_place_submit_value(value)
          if @original_value != value
            if editor == 'switch'
              value = nil if value == '0.5'
            end

            if requirement == 'mandatory' && value.blank?
              @success = false
              change_value(@original_value)
              error = {error: :blank}
              form.error!(error)
            else
              @loading = true
              @success = nil
              around_edit_in_place_submit_value do
                record.update({ attribute_name => value }, @edit_in_place_submit_options).then do |response|
                  @success = response[:success]
                  @loading = false
                  @success ? form.success!(response, form) : form.error!(response, form)
                  mutate
                end
              end
            end
          end
          @edit = false
          mutate
        end

        def render_edit_in_place_editing_with_autocomplete
          InputWithAutocomplete(input_with_autocomplete_args).on(:change) do |event|
            change_value(event.target.value)
          end.on(:focus) do |event|
            @original_value = edit_in_place_original_value(event)
            event.target.select
          end.on(:select) do |event, item|
            edit_in_place_with_autocomplete_submit_value(item)
          end.on(:blur) do |event|
            after(0.1) do
              @edit = false
              mutate
            end
          end.on(:key_escape) do |event|
            change_data(@original_value)
            @edit = false
            mutate
          end
          input_errors
        end

        def edit_in_place_with_autocomplete_submit_value(item)
          @loading = true
          @success = nil
          around_edit_in_place_submit_value do
            record.update(item['record'], @edit_in_place_submit_options).then do |response|
              autocomplete_clear_elements if autocomplete_clear_elements?
              change_values(*convert_record_hash_to_values(item['record']))
              @success = response[:success]
              @loading = false
              @success ? form.success!(response, form) : form.error!(response, form)
              mutate
            end
          end
          @edit = false
          mutate
        end

        def render_edit_in_place_not_editing
          edit_in_place_fake_input do
            edit_in_place_value_container do
              empty_and_show_placeholder? ? placeholder : edit_in_place_displayed_value
            end
          end.on(:click) do |event|
            next if event.target['nodeName'] == 'A'
            event.prevent_default
            @edit = true
            mutate
          end
        end

        def edit_in_place_displayed_value
          read_only_displayed_value
        end

        # read_only -----------------------------------------------------------

        def read_only_displayed_value
          form.submission.read(path).to_s
        end

        # cell ----------------------------------------------------------------

        def render_edit_cell
          layout_edit_cell do
            render_edit_in_place_editing
          end
        end

        # hidden --------------------------------------------------------------

        def render_input_hidden
          unless in_editor
            INPUT(input_args.merge(type: 'hidden'))
          else
            render_input_hidden_in_editor
          end
        end

        def render_input_hidden_in_editor
          layout_input_hidden do
            INPUT(
              id: input_id,
              name: input_name,
              value: form&.submission&.read(path),
              type: 'text',
              class: "form-control #{invalid_css_class} #{input_class}",
            ){}
          end
        end

      end
    end
  end
end
