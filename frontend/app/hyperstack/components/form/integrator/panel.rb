# backtick_javascript: true

class Form
  class Integrator
    module Panel
      class Base < HyperComponent
        include ::UrlHelper
        @@current_schema_info = {}
        param :element, default: {}
        collect_other_params_as :other_params

        def initialize(native)
          super
          @preview_url = ""
          @modal_params = nil
          @pending_async_operations = 0
        end

        before_mount do
          @current_belongs_to_id_target ||= generate_belongs_to_id
          @current_belongs_to_id_src ||= generate_belongs_to_id
          restore_state_from_element
          update_preview_url
        end

        render { content }

        def label
          return I18n.t("crm.form_integrator.value")
        end

        def content
          DIV(class: 'container-fluid pt-4') do
            render_element_specific_section
            render_iframe_parameters_section
          end
        end

        def restore_state_from_element
          ::Form::Integrator::Store.initialize_defaults
          @source_record_type = ::Form::Integrator::Store.source_record_type
          @source_record_id = ::Form::Integrator::Store.source_record_id
          @target_record_type = ::Form::Integrator::Store.target_record_type
          @target_record_id = ::Form::Integrator::Store.target_record_id
          @iframe_height = ::Form::Integrator::Store.iframe_height || 600
          @preview_url = ::Form::Integrator::Store.preview_url || ""
          saved_params = ::Form::Integrator::Store.additional_params
          @additional_params = saved_params.is_a?(Array) ? saved_params : []
          @additional_params_hash = ::Form::Integrator::Store.additional_params_hash || {}
        end

        def handle_iframe_form_change(form)
          if form && form.submission
            current_global_params = ::Form::Integrator::Store.additional_params || []
            current_url_hash = ::Form::Integrator::Store.additional_params_hash || {}
            updated_settings = {
              source_record_id: @source_record_id,
              target_record_id: @target_record_id,
              iframe_height: @iframe_height,
              additional_params: current_global_params,
              additional_params_hash: current_url_hash,
              preview_url: @preview_url
            }
            ::Form::Integrator::Store.update_settings(updated_settings)
          end
        end

        def self.current_schema_info=(info)
          @@current_schema_info = info
        end

        def self.current_schema_info
          @@current_schema_info
        end

        def accordion_style
          return {width: 'calc(100% + 30px)', position: 'relative', left: '-15px'}
        end

        def render_element_specific_section
          ::Form::Element::Layout::Accordion(
            title: I18n.t("crm.form_integrator.heading_params"),
            style: accordion_style
          ) do
            Form( record: initialized_model_record ) do
              parameters
            end.on(:change) do |form|
              handle_element_form_change(form)
            end
          end
        end

        def initialized_model_record
          @initialized_model_record ||= create_initialized_model
        end

        def create_initialized_model
          return record unless record&.respond_to?(:klass_name) && record.klass_name.present?
          model_class = record.klass_name.safe_constantize
          return nil unless model_class
          temp_model = model_class.new
          element_data = element.respond_to?(:to_h) ? element.to_h : Hash.new(element)
          setup_dynamic_attributes(temp_model, element_data)
          process_element_data_async(temp_model, element_data)
          temp_model
        end

        def setup_dynamic_attributes(temp_model, element_data)
          element_data.keys.select { |k| k.to_s.start_with?('default_params_') }.each do |key|
            attr_name = key.to_s
            temp_model.define_singleton_method(attr_name) { instance_variable_get("@#{attr_name}") }
            temp_model.define_singleton_method("#{attr_name}=") { |v| instance_variable_set("@#{attr_name}", v) }
          end
        end

        def process_element_data_async(temp_model, element_data)
          @pending_async_operations = 0
          element_data.each do |key, value|
            next unless key.to_s.start_with?('default_params_') && value.present?
            attr_name = key.to_s
            case value
            when Array
              if attr_name.end_with?('_attributes')
                load_has_many_collection_async(temp_model, attr_name.gsub(/_attributes$/, ''), value)
              end
            when Hash
              if value['id'] && value['type']
                load_belong_to_record_async(temp_model, attr_name, value)
              else
                temp_model.send("#{attr_name}=", value)
              end
            else
              temp_model.send("#{attr_name}=", value)
            end
          end
          mutate if @pending_async_operations == 0
        end

        def load_has_many_collection_async(model, attr_name, items)
          return unless items.is_a?(Array) && items.any?
          collection = []
          items_to_load = items.select { |item| item.is_a?(Hash) && item['id'] && item['type'] }
          return if items_to_load.empty?
          @pending_async_operations += items_to_load.length
          items_to_load.each do |item|
            target_class = item['type'].safe_constantize
            next unless target_class
            target_class.find(item['id']) do |distant_record|
              @pending_async_operations -= 1
              if distant_record.loaded?
                if record_is_hydrated?(distant_record, :has_many)
                  collection << distant_record
                end
              end
              if @pending_async_operations == 0
                model.send("#{attr_name}=", collection)
                mutate
              end
            end
          end
        end

        def load_belong_to_record_async(model, attr_name, value)
          target_class = value['type'].safe_constantize
          return unless target_class
          @pending_async_operations += 1
          target_class.find(value['id']) do |reponse_record|
            @pending_async_operations -= 1
            if reponse_record.loaded?
              if record_is_hydrated?(reponse_record, :single)
                model.send("#{attr_name}=", reponse_record)
              else
                model.send("#{attr_name}=", nil)
              end
            else
              model.send("#{attr_name}=", nil)
            end
            mutate if @pending_async_operations == 0
          end
        end

        def record_is_hydrated?(record, type)
          return false unless record
          case type
          when :has_many
            record.respond_to?(:name) && record.respond_to?(:polymorphic_name) && record.polymorphic_name.present?
          when :simple
            record.try(:name) || record.try(:polymorphic_name) || record.respond_to?(:id)
          when :single
            record.try(:name) || record.try(:polymorphic_name)
          else
            true
          end
        end

        def render_iframe_parameters_section
          Form( record: record, enable_after_user_interaction: true ) do
            ::Form::Element::Layout::Accordion(
              title: I18n.t("crm.form_integrator.heading_settings"),
              style: accordion_style,
            ) do
              RecordSection(
                type: 'source',
                record_type: source_klass,
                record_id: @source_record_id,
                belongs_to_id: @current_belongs_to_id_src,
              ).on(:id_change) do |value|
                handle_source_id_change(value)
                update_preview_url
                Form.current.enable
              end

              RecordSection(
                type: 'target',
                record_type: target_klass,
                record_id: @target_record_id,
                belongs_to_id: @current_belongs_to_id_target,
              ).on(:id_change) do |value|
                handle_target_id_change(value)
                update_preview_url
              end

              ParamsSection(
                additional_params: @additional_params,
                key: "params-#{@additional_params.hash}"
              ).on(:changed) do
                focus_first_element_form_input
              end
            end

            IframeSection(
              iframe_code: generate_iframe_code,
              preview_url: @preview_url,
              iframe_height: @iframe_height,
              modal_params: @modal_params,
              accordion_style: accordion_style
            ).on(:preview_requested) do
              preview
            end.on(:copy_link_requested) do |url|
              copy_to_clipboard(url)
            end.on(:copy_code_requested) do |code|
              copy_to_clipboard(code)
            end.on(:height_changed) do |new_height|
              @iframe_height = new_height
              ::Form::Integrator::Store.update_settings({
                iframe_height: @iframe_height
              })
              Form.current.enable if Form.current
              update_preview_url
            end.on(:show_modal_requested) do |modal_data|
              show_modal(modal_data)
            end.on(:close_modal_requested) do
              @modal_params = nil
              mutate
            end
          end.on(:change) do |form|
            handle_iframe_form_change(form)
          end
        end

        def parameters
          DIV { I18n.t("crm.form_integrator.missing_setting") }
        end

        def generate_belongs_to_id
          "belongs-to-#{Time.now.to_i}-#{rand(10000)}"
        end

        def handle_element_form_change(form)
          context = setup_context
          return unless context
          attribute_name = element[:attribute_name].to_s
          field_info = build_field_info(element)
          extract_and_update_parameters(form, context[:root_key], attribute_name, field_info)
          cleanup_empty_params(context[:root_key])
          trigger_updates(form)
        end


        private


        def setup_context
          root_klass_obj = determine_base_class_for_context
          return nil unless root_klass_obj&.name.present?
          root_klass_name = root_klass_obj.name.demodulize.underscore
          {
            root_klass_obj: root_klass_obj,
            root_key: "#{root_klass_name}@0"
          }
        end

        def build_field_info(element)
          type_str = element[:type].to_s
          return :has_many if type_str.include?('HasMany')
          return :belongs_to if type_str.include?('BelongsTo')
          nil
        end

        def extract_has_many_raw_data(submission_values, key_prefix)
          (0..).each_with_object([]) do |index, result|
            id_key = key_prefix + [index, "id"]
            type_key = key_prefix + [index, "type"]
            id_value = submission_values[id_key]
            break result unless id_value
            result << { "id" => id_value, "type" => submission_values[type_key] }
          end
        end

        def extract_and_update_parameters(form, root_key, attribute_name, field_info)
          @additional_params_hash[root_key] ||= {}
          case field_info
          when :has_many
            extract_and_update_has_many(form, root_key, attribute_name)
          when :belongs_to
            extract_and_update_belongs_to(form, root_key, attribute_name)
          else
            extract_and_update_simple(form, root_key, attribute_name)
          end
        end

        def extract_and_update_has_many(form, root_key, attribute_name)
          prefix = ["base", "default_params_#{attribute_name}"]
          items = extract_has_many_raw_data(form.submission.values, prefix)
          clean_has_many_entries(root_key, attribute_name)
          items.each_with_index do |item, index|
            key = "#{root_key}.#{attribute_name}@#{index}"
            item_value = { "id" => item["id"] }
            item_value["type"] = item["type"] if item["type"]
            @additional_params_hash[key] = item_value
            update_ui_param_list(key, item["id"])
          end
        end

        def extract_and_update_belongs_to(form, root_key, attribute_name)
          key = ["base", "default_params_#{attribute_name}"]
          data = form.submission.values[key]
          value = nil
          id = nil
          if data.is_a?(Hash)
            id = data["id"] || data[:id]
            value = { "id" => id, "type" => data["type"] || data[:type] }.compact
          elsif data.respond_to?(:id)
            id = data.id
            value = { "id" => id, "type" => data.class.name }
          end
          value = { "id" => id } if id && !value&.key?("type")
          flat_key = "#{root_key}.#{attribute_name}@0"
          if value.present?
            @additional_params_hash[flat_key] = value
            update_ui_param_list(flat_key, id)
          else
            @additional_params_hash.delete(flat_key)
            @additional_params.delete_if { |p| p[:name] == flat_key }
          end
        end

        def extract_and_update_simple(form, root_key, attribute_name)
          key = ["base", "default_params_#{attribute_name}"]
          value = form.submission.values[key]
          hash_key = attribute_name
          ui_key = "#{root_key}.#{attribute_name}"
          if value.present?
            @additional_params_hash[root_key][hash_key] = value
            update_ui_param_list(ui_key, value)
          else
            @additional_params_hash[root_key].delete(hash_key)
            @additional_params.delete_if { |p| p[:name] == ui_key }
          end
        end

        def update_ui_param_list(name, value)
          existing = @additional_params.find { |p| p[:name] == name }
          if existing
            existing[:value] = value
          else
            @additional_params << { name: name, value: value }
          end
        end

        def clean_has_many_entries(root_key, attribute_name)
          prefix = "#{root_key}.#{attribute_name}@"
          @additional_params_hash.delete_if { |key, _| key.start_with?(prefix) }
          @additional_params.delete_if { |param| param[:name].start_with?(prefix) }
        end

        def cleanup_empty_params(root_key)
          @additional_params_hash.delete(root_key) if @additional_params_hash[root_key]&.empty?
          belongs_to_prefix = "#{root_key}."
          @additional_params_hash.delete_if { |key, value|
            key.start_with?(belongs_to_prefix) && key.end_with?("@0") && value.blank?
          }
        end

        def trigger_updates(form)
          ::Form::Integrator::Store.update_settings({
            additional_params_hash: @additional_params_hash.dup,
            additional_params: @additional_params.dup
          })
          update_preview_url
          attrs = form&.submission&.params&.values&.first
          callback = other_params&.dig(:updateSelectedElementAttributes)
          callback.call(attrs.to_n) if attrs && callback
        end

        def compute_klass(type, klass_name_method)
          klass = self.class.current_schema_info[klass_name_method]
          return nil unless klass
          ::Form::Integrator::Store.update_settings(
            "#{type}_record_type": klass
          )
          update_preview_url
          instance_variable_set(:"@#{type}_record_type", klass)
          klass
        end

        def source_klass
          compute_klass(:source, :base_class)
        end

        def target_klass
          compute_klass(:target, :target_klass_name)
        end

        def determine_base_class_for_context
          if self.class.current_schema_info[:base_class].present?
            return self.class.current_schema_info[:base_class].safe_constantize
          end
          nil
        end

        def record
          return @record if @record
          element_hash = element.is_a?(Hash) ? element : Hash.new(element.to_n)
          if @record && element_hash['id'] && element_hash['updated_at']
            if element_hash['id'] != @record.id || element_hash['updated_at'] != @record.updated_at
              @record = nil
            end
          end
          @record ||= ::Dynamic::Form::Element::Base.polymorphic_new(element_hash) unless element_hash.empty?
        end

        def handle_source_id_change(value)
          if value.is_a?(Hash) && value.key?("id")
            @source_record_id = value["id"]
          elsif value.is_a?(Hash) && value.key?(:id)
            @source_record_id = value[:id]
          elsif value.respond_to?(:id)
            @source_record_id = value.id
          else
            @source_record_id = value
          end
          ::Form::Integrator::Store.update_settings({
            source_record_id: @source_record_id
          })
          update_preview_url
        end

        def handle_target_id_change(value)
          @target_record_id = value.is_a?(Object) && value.respond_to?(:id) ? value.id : value
          ::Form::Integrator::Store.update_settings({
            target_record_id: @target_record_id
          })
        end

        def focus_first_element_form_input
          first_input = ::Element.find('.form-editor-center-panel-container .row.form-group').first
          first_input&.trigger(:click)
        end

        def show_modal(params = {})
          @modal_params = params
          mutate
          after(0.1) do
            mutate
            ::Element['#form-integrator-modal'].modal('show')
          end
        end

        def update_preview_url
          form_url_base = get_host_origin
          schema_info = self.class.current_schema_info
          form_id = schema_info[:form_id]
          permalink_name = schema_info[:permalink]
          return unless permalink_name.present?
          permalink = permalink_name.demodulize.underscore
          base_url = "#{form_url_base}/crm/#{permalink}/forms/#{form_id}"
          query_params = build_query_params
          @preview_url = query_params.empty? ? base_url : "#{base_url}?#{encode_url_params(query_params)}"
          mutate
        end

        def build_query_params
          query_params = {}
          if @source_record_id.present? && @source_record_type.present?
            query_params["source_record_id"] = @source_record_id
            query_params["source_record_type"] = @source_record_type
          end
          if @target_record_id.present? && @target_record_type.present?
            query_params["target_record_id"] = @target_record_id
            query_params["target_record_type"] = @target_record_type
          end
          nested_params = ::Form::Integrator::Store.additional_params_hash || {}
          query_params["params"] = nested_params if nested_params.present?
          query_params
        end

        def get_host_origin
          `window.location.origin`
        end

        def copy_to_clipboard(text)
          `navigator.clipboard.writeText(#{text})`
        end

        def preview
          `window.open(#{@preview_url.to_s.to_n}, "_blank")`
        end

        def generate_iframe_code
          return "" unless @preview_url && @preview_url.length > 0
          host_origin = get_host_origin
          loading_message = generate_loading_message
          script_js = build_iframe_script(host_origin)
          %{#{loading_message}<iframe name="iframe1" src="#{@preview_url}" width="100%" height="#{@iframe_height}" frameborder="0"></iframe>#{script_js}}
        end

        def generate_loading_message
          message_text = ::Form::Integrator::Store.loading_message_text.presence
          return unless message_text
          styles = ::Form::Integrator::Store.get_loading_message_styles
          style_string = styles.map { |k, v| "#{k.to_s.gsub(/([A-Z])/, '-\1').downcase}: #{v}" }.join('; ')
          %{<div style="text-align: center;"><span style="#{style_string}">#{message_text}</span></div>}
        end

        def build_iframe_script(host_origin)
          <<~JAVASCRIPT
            <script type="text/javascript">
              window.addEventListener("message", function(event) {
                if (event.origin !== "#{host_origin}") return;
                if (!event.data.iframeName) return;
                const iframe = document.getElementsByName(event.data.iframeName)[0];
                const load = iframe.previousElementSibling;
                if (event.data.iframeFormLoaded && load && load.childNodes.length) {
                  load.style.display = "none";
                }
                if (event.data.iframe_height && iframe) {
                  iframe.style.height = event.data.iframe_height + "px";
                }
                if (event.data.redirect &&
                    (!event.data.redirect.blocker || window.location.search.indexOf(event.data.redirect.blocker) < 0)) {
                  var url = event.data.redirect.url;
                  window.location = url;
                }
              }, false);
            </script>
          JAVASCRIPT
        end
      end
    end
  end
end
