# backtick_javascript: true

class Crm
  class Merge
    class Setting < Base
      include ::Crm::CrmLayout
      before_mount do
        init_local_variables
        fill_record_to_merge_index if request.params['action'] == 'new'
      end

      render(DIV) do
        next unless schema.constants_loaded?
        layout_with_toolbar(class: "overflow-auto") do
          error_messages
          table
          footer
        end
      end

      def error_messages
        if setting.errors.present? && setting&.run_errors.blank?
          ErrorMessage(record: setting, timestamp: @timestamp, blacklist: /result_record\./, class: 'm-2')
        elsif Hyperstack.env == 'development' && setting&.run_errors.present?
          setting.errors = setting.run_errors
          DIV(class: 'text-danger m-3') do
            DIV do
              setting&.run_errors[:message] || setting["run_errors"]
            end
            if setting&.run_errors[:backtrace].present?
              Link { 'backtrace' }.on(:click) { toggle(:show_backtrace)}
            end
            if @show_backtrace
              DIV { setting&.run_errors[:backtrace].join("\n") }
            end
          end
        elsif Hyperstack.env != 'development' && setting&.run_errors.present?
          setting.errors = setting.run_errors
        end
        if record_to_merge_id_blank? && request.params['action'] == 'new'
          DIV(class: "m-2 alert alert-danger") do
            I18n.t('shared.nothing_selected')
          end
        elsif setting&.not_found?
          DIV(class: "m-2 alert alert-danger") do
            I18n.t('activerecord.exceptions.not_found', model_name: setting.result_record_klass.model_name.human)
          end
        end
      end

      def record_to_merge_id_blank?
        request.params[:record_to_merge_ids]&.size == 1 && request.params[:record_to_merge_ids][0].blank?
      end

      def init_local_variables
        @selected_attributes = Hash.new
        @show_form = nil
        @timestamp = 0
        @disabled = false
        @setting = nil
        @delete_record_to_merges = []
        @record_to_merges_index = {}
        @hidden_field_names = nil
        @visible_field_names = nil
        @show_hidden_field_names = false
        @default_attributes_filled = false if @default_attributes_filled.nil?
        @all_field_names = nil
        @available_record_to_merges = nil
      end

      def table
        return unless show_table?
        background do
          DIV(class: "d-flex flex-row") do
            TABLE(class: "table #{'text-muted' if @disabled}", style: {tableLayout: available_record_to_merges.length <= 3 ? 'fixed' : 'auto'})do
              THEAD(class: "bg-light") do
                TR do
                  TH(class: 'text-nowrap align-middle', style: {width: '15%'}) do
                    I18n.t("crm.merge.setting.fields")
                  end
                  TH(class:'text-nowrap align-middle') do
                    I18n.t("crm.merge.setting.merged_version")
                  end
                  available_record_to_merges.each do |record|
                    TH(class: "#{'alert alert-danger' if has_ongoing_merge_error(record)} text-nowrap align-middle") do
                      DIV(class:'d-flex flex-row') do
                        DIV(class:'align-self-start') do
                          DIV(class:"btn btn-sm btn-transparent-light-yiq shadow-none cursor-pointer") do
                            SPAN(class:"fa-regular fa-square#{'-check' if check_all_attributes(record)} fa-lg ") do
                            end
                          end.on(:click) do
                            select_or_unselect_all(record)
                            @timestamp += 1
                            mutate
                          end
                        end
                        DIV(class: 'flex-grow-1 text-nowrap') do
                          SPAN(class: 'text-overflow-dynamic-container') do
                            SPAN(class: 'text-overflow-dynamic-ellipsis text-center column-title pt-1') do
                              "#{record.class.model_name.human} #{@record_to_merges_index[record.id]}"
                            end
                            SPAN(class: 'column-order') do
                            end
                          end
                        end
                        DIV(class: 'align-self-end') do
                          DIV(class: 'btn btn-sm btn-transparent-light-yiq shadow-none cursor-pointer') do
                            SPAN(class: 'fa fa-times fa-lg') do
                            end
                          end.on(:click) do |event|
                            event.stop_propagation
                            Modal.confirm do
                              all_field_names.each do |field_name|
                                modal_for_delete_a_record(@selected_attributes, record, field_name)
                              end
                              @timestamp += 1
                              @delete_record_to_merges.push({
                                id: record.id,
                                _destroy: '1',
                                type: record.class.name,
                              })
                              @visible_field_names = nil
                              @hidden_field_names = nil
                              @available_record_to_merges = nil
                              mutate
                            end
                          end
                        end
                      end
                    end
                  end
                end
              end
              TBODY do
                visible_field_names.each do |field_name|
                  TR do
                    row_klass(field_name).create_element(
                      field_name: field_name,
                      selected_attributes: @selected_attributes,
                      setting: setting,
                      show_form: @show_form == field_name,
                      disabled: @disabled,
                      available_record_to_merges: available_record_to_merges,
                      timestamp: @timestamp
                    ).on(:edit) do
                      @show_form = field_name
                      mutate
                    end
                  end
                end

                if @show_hidden_field_names
                  hidden_field_names.each do |field_name|
                    TR do
                      row_klass(field_name).create_element(
                        field_name: field_name,
                        selected_attributes: @selected_attributes,
                        setting: setting,
                        show_form: @show_form == field_name,
                        disabled: @disabled,
                        available_record_to_merges: available_record_to_merges,
                        timestamp: @timestamp
                      ).on(:edit) do
                        @show_form = field_name
                        mutate
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end

      def background
        DIV(class: "d-flex flex-column h-100") do
          yield
          DIV(class: 'flex-grow-1 mb-5') do
          end
        end.on(:click) { mutate @show_form = nil }
      end

      def show_table?
        return false if record_to_merge_id_blank? && request.params['action'] == 'new'
        return false if setting&.not_found?
        return false unless setting.present?
        return false unless setting.status_code == 422 || setting.new_record? && setting.loaded? || setting.loaded?
        return true
      end

      def footer
        return unless show_table?
        DIV(class: "d-flex position-fixed mb-2 mr-3", style: {bottom: 0, right: 0}) do
          if Hyperstack.env == 'development'
            DIV(class: "mr-1 btn btn-secondary ml-auto mb-2", type: "button") { I18n.t("crm.merge.setting.update_settings") }.on(:click) do
              update_field_setting
            end
          end
          DIV(class: "btn btn-primary #{'disabled' if @disabled} mb-2", type: "button") { I18n.t("crm.merge.setting.merge") }.on(:click) do
            next if @disabled
            run
            mutate
          end
        end
      end

      def row_klass(field_name)
        Row.klass_from_field_name(setting.result_record_klass, field_name)
      end

      def hidden_field_names
        return [] if available_record_to_merges.length == 1
        compute_field_name_visibility unless @hidden_field_names
        return @hidden_field_names
      end

      def visible_field_names
        return all_field_names if available_record_to_merges.length == 1
        compute_field_name_visibility unless @visible_field_names
        fill_up_selected_attributes_by_default if attributes_unfilled?
        return @visible_field_names
      end

      def compute_field_name_visibility
        @visible_field_names = []
        @hidden_field_names = []

        all_field_names.each do |field_name|
          is_same_values = row_klass(field_name).field_with_same_values?(field_name, setting, available_record_to_merges)
          if is_same_values
            @hidden_field_names.push(field_name)
          else
            @visible_field_names.push(field_name)
          end
        end
        @hidden_field_names.each do |field_name|
          row_klass(field_name).fill_up_selected_attributes(@selected_attributes, available_record_to_merges[0], field_name)
        end
      end

      def fill_up_selected_attributes_by_default
        @visible_field_names.each do |field_name|
          next unless row_klass(field_name).select_all_by_default?
          available_record_to_merges.each do |available_record_to_merge|
            row_klass(field_name).fill_up_selected_attributes(@selected_attributes, available_record_to_merge, field_name)
          end
        end
        @default_attributes_filled = true
      end

      def attributes_unfilled?
        setting.new_record? && !setting.errors.present? && !@default_attributes_filled
      end

      def available_record_to_merges
        return @available_record_to_merges if @available_record_to_merges.present?

        if @delete_record_to_merges.present?
          ids = @delete_record_to_merges.map{ |r| r[:id] }
          @available_record_to_merges = setting.record_to_merges.select{ |r| !ids.include?(r.id) }
        else
          @available_record_to_merges = setting.record_to_merges
        end
        return @available_record_to_merges
      end

      def all_field_names
        return @all_field_names if @all_field_names.present?
        result = []
        attrs = []
        if setting.record_to_merges[0].blank? && setting.result_record.present?
          @disabled = true
          attrs = setting.result_record.attributes
        elsif setting.record_to_merges[0].present?
          attrs = setting.record_to_merges[0].attributes
        end
        klass = setting.result_record_klass
        attrs.each do |k, v|
          next if black_list.include?(k)
          next if I18n.available_locales.detect{|l| attrs.include?("#{k}_#{l}") }
          if k.end_with?("_id") || k.end_with?("_type")
            n = k.gsub(/_id$|_type$/, '')
            next if klass.reflect_on_association(n) || klass.reflect_on_attachment(n)
          end
          next if k == 'type' && setting.record_to_merges.map{|r| r.class.name }.uniq.length <= 1
          result << k
        end
        result.concat(
          setting.result_record_klass.reflect_on_all_associations.select{|a| !a.try(:schema_association_through_name) }.map(&:name)
        ).concat(
          setting.result_record_klass.reflect_on_all_attachments.map(&:name)
        )
        @all_field_names = result
        return result
      end

      def black_list
        return ["id", "updated_at", "deleted_at", "polymorphic_name", "translations"]
      end

      def select_or_unselect_all(record)
        a = check_all_attributes(record)
        all_field_names.each do |field_name|
          if a
            row_klass(field_name).unselect_all_fields(@selected_attributes, record, field_name,setting, @timestamp)
          else
            row_klass(field_name).fill_up_selected_attributes(@selected_attributes, record, field_name, @timestamp)
          end
        end
      end

      def check_all_attributes(record)
        return false if all_field_names.length != @selected_attributes.keys.length

        @selected_attributes.each do |field|
          return false unless check_field(field, record)
        end

        return true
      end

      def fields_attributes
        result = []
        @selected_attributes.each do |attribute_name, value|
          record_for_attachement = nil
          if setting.result_record_klass.reflect_on_attachment(attribute_name) && value.is_a?(Hash)
            record_for_attachement = setting.record_to_merges.detect {|r| r.id == value[:from_id]}
          end
          update_field = setting.fields.detect { |t| t.name == attribute_name }

          result << row_klass(attribute_name).fields_attributes(attribute_name, value, update_field, record_for_attachement)
        end
        return result
      end

      def has_ongoing_merge_error(record)
        if setting.errors && setting.errors[:record_to_merges]
          return setting.errors[:record_to_merges].any?{|err| err[:record_id] == record.id}
        end
        false
      end

      def modal_for_delete_a_record(selected_attributes, record, field_name)
        row_klass(field_name).delete_a_record(selected_attributes, record, field_name, @timestamp)
      end

      def update_field_setting
        mutate @show_form = nil
        if setting.new_record?
          setting_attributes = setting.attributes.merge(fields_attributes: fields_attributes, record_to_merge_ids: record_to_merge_ids)
        else
          setting_attributes = { fields_attributes: fields_attributes }
        end
        setting.update(setting_attributes).then do |response|
          if response[:success]
            puts "success"
            if request.params['action'] == 'new'
              redirect_to_edit_merge_setting
            else
              @selected_attributes.clear
              mutate @timestamp += 1
            end
          else
            puts "error"
            mutate @timestamp += 1
          end
        end
      end

      def run
        @disabled = true
        mutate @show_form = nil
        return unless setting.status == 'not_started' || setting.run_errors.present?

        if setting.new_record?
          setting_attributes = setting.attributes.merge(fields_attributes: fields_attributes, status: :to_do, record_to_merge_ids: record_to_merge_ids)
        else
          setting_attributes = { fields_attributes: fields_attributes, status: :to_do }
        end

        setting.update(setting_attributes).then do |response|
          if response[:success]
            @selected_attributes.clear
            redirect_to_index
          else
            @disabled = false
            mutate @timestamp += 1
          end
        end
      end

      def back
        previous_request = request_history.detect{|r| !(r.location.pathname =~ /merge_settings/) }
        if previous_request
          App.history.push(previous_request.location)
        else
          redirect_to_index
        end
      end

      def redirect_to_index
        schema = request.params[:schema_id]
        klass_name = setting.result_record_klass.model_name.route_key
        url = "/crm/#{schema}/table/#{klass_name}/last_search"
        App.history.push(additional_params(url))
      end

      def redirect_to_edit_merge_setting
        schema_id = request.params[:schema_id]
        url = "/crm/#{schema_id}/merge_settings/#{setting.id}/edit"
        App.history.push(additional_params(url))
      end

      def additional_params(url)
        url = add_param_to_url(url, :mi, request.params[:mi]) if request.params[:mi].present?
        return url
      end

      def fill_record_to_merge_index
        request.params[:record_to_merge_ids].each_with_index do |id, i|
          @record_to_merges_index[id] = i+1
        end
      end

      def setting
        if request.params[:action] == 'new'
          return @setting if @setting.present?
          # # Improve hyperresource in order to load the new record #
          # observe @setting = setting_class.includes(setting_class.includes_for_load).new(id: 'new', base: {result_record_type: request.params[:result_record_type], record_to_merge_ids: record_to_merge_ids})
          # @setting.load
          @setting = setting_class.includes(setting_class.includes_for_load).new(result_record_type: request.params[:result_record_type])
          query = setting_class.member_path(id: 'new', base: { result_record_type: request.params[:result_record_type], record_to_merge_ids: record_to_merge_ids}, include: setting_class.includes_for_load)
          HyperResource::HTTP.get(query).then do |response|
            @setting = setting_class.includes(setting_class.includes_for_load).new(response.json)
            @setting.status_code = response.status_code
            mutate
          end.fail do |response|
            @setting.status_code = response.status_code
            mutate
          end
          @setting
        else
          observe setting_class.includes(setting_class.includes_for_load).find(request.params[:setting_id])
        end
      end

      def record_to_merge_ids
        return [] if record_to_merge_id_blank?
        result = []
        rec_ids = request.params[:record_to_merge_ids] - @delete_record_to_merges.map{ |r| r[:id] }
        rec_ids.each do |id|
          result << {id: id, type: request.params[:result_record_type]}
        end
        result
      end

      def setting_class
        "D::#{schema.name}::R::Merge::Setting".safe_constantize
      end

      def global_toolbar_title
        DIV(class: "btn btn-transparent-primary shadow-none cursor-pointer") do
          I(class: 'fas fa-chevron-left mr-2') do
          end
          I18n.t("shared.back")
        end.on(:click) do
          back
        end
      end

      def global_toolbar_menu_items
        if show_table? && hidden_field_names.try(:any?)
          DIV(class: "btn btn-transparent-primary shadow-none cursor-pointer") do
            if @show_hidden_field_names
              I18n.t("crm.merge.setting.hide_identical_lines")
            else
              I18n.t("crm.merge.setting.show_identical_lines")
            end
          end.on(:click) do
            toggle(:show_hidden_field_names)
          end
        end
      end

      private

      def check_field(field, record)
        if field[1].is_a?(Hash)
          hash_field_check(field[1], record)
        elsif field[1].is_a?(Array)
          array_field_check(field[1], record, field[0])
        else
          false
        end
      end

      def hash_field_check(field_data, record)
        field_data[:from_id] == record.id
      end

      def array_field_check(field_data, record, field_name)
        all_records_selected?(field_data, record, field_name) || all_attachments_selected?(field_data, record, field_name)
      end

      def all_records_selected?(field_data, record, field_name)
        record_values = record.send(field_name).to_a
        selected_values = field_data.map { |a| a[:record] }
        record_values == (record_values & selected_values)
      end

      def all_attachments_selected?(field_data, record, field_name)
        return false unless record.class.reflect_on_attachment(field_name)

        attachment = record.send(field_name)
        record_signed_ids = attachment.attachments.map(&:signed_id)
        selected_signed_ids = field_data.map { |a| a[:signed_id] }
        record_signed_ids == (record_signed_ids & selected_signed_ids)
      end

      module Row
        def self.klass_from_field_name(record_class, field_name)
          if record_class.attributes[field_name]
            "#{self.name}::Attribute::#{record_class.attributes[field_name]['type'].classify}".safe_constantize || Attribute::Base
          elsif record_class.reflect_on_association(field_name)
            "#{self.name}::Association::#{record_class.reflect_on_association(field_name).class.name.demodulize.gsub(/Reflection\z/, '')}".safe_constantize || Association::Base
          elsif record_class.reflect_on_attachment(field_name)
            "#{self.name}::Attachment::#{record_class.reflect_on_attachment(field_name).macro.classify}".safe_constantize || Attachment::Base
          elsif self.translatable?(field_name)
            "#{self.name}::Attribute::#{record_class.attributes[remove_locale_from_name(field_name)]['type'].classify}".safe_constantize || Attribute::Base
          elsif field_name == 'type'
            Type
          else
            raise "unknown #{field_name} for #{record_class&.name}"
          end
        end

        def self.translatable?(field_name)
          return field_name && !!I18n.available_locales.detect{|l| field_name.end_with?("_#{l}")}
        end

        def self.remove_locale_from_name(field_name)
          l = I18n.available_locales.detect{|l| field_name.end_with?("_#{l}")}
          field_name.sub(/_#{l}$/, '')
        end

        class Base < HyperComponent
          param :field_name
          param :selected_attributes
          param :setting
          param :show_form, default: false
          param :disabled, default: false
          param key: ''
          collect_other_params_as :other_params
          fires :click
          fires :edit

          render do
            field_name_label
            if setting.result_record.present?
              TD do
                record_values(setting.result_record)
              end
            end
            display_selected_value.on(:click) do |event|
              next if disabled

              event.stop_propagation
              edit!(field_name)
              mutate
            end
            other_params[:available_record_to_merges].each do |record|
              handle_record_values_clicked(record)
            end
          end

          def handle_record_values_clicked(record)
          end

          def field_name_label
            TD(class: "#{field_errors?(field_name) ? 'text-danger' : :none}", style: {minWidth: '200px'}) { setting.result_record_klass.human_attribute_name(field_name) }
          end

          def display_selected_value
            TD(class: "cursor-text #{'py-0' if padding_top_unnecessary?}") do
              DIV do
                if show_form
                  form(field_name)
                else
                  if selected_value
                    record_values(selected_value, not_selected=true)
                  end
                end
              end
              if setting.errors.present?
                setting.errors["result_record.#{field_name}"]&.each do |e|
                  DIV class: 'text-danger small' do
                    I18n.error(e, setting, "result_record.#{field_name}")
                  end
                end
              end
            end
          end

          def padding_top_unnecessary?
            false
          end

          def record_values#can be redefined
          end

          def selected_value#can be redefined
          end

          def field_errors?(field_name)
            setting.errors.has_key?("result_record.#{field_name}")
          end

          def selected#can be redefined
          end

          def form(field_name)
            Form(record: selected_value(field_name)) do
              Form::Element.klass_from_method_name(setting.result_record_klass, field_name).create_element(attribute_name: field_name, show_label: false, show_value: false, auto_focus: true)
            end.on(:change) do |form|
              reflection = setting.result_record_klass.reflect_on_association(field_name)
              value_in_form = form.submission.params.dig("base")
              if reflection
                values = value_in_form.values.flatten.map { |v| { value_type: reflection.klass, value_id: v[:id] } }
                result = { values_attributes: values}
              elsif setting.result_record_klass.reflect_on_attachment(field_name).is_a?(HyperResource::ActiveStorage::Reflection::HasOneAttachedReflection)
                @filename = form.submission.data.dig("base", field_name).filename
                result = { values_attributes: [{ value: value_in_form[field_name]}]}
              elsif setting.result_record_klass.reflect_on_attachment(field_name).is_a?(HyperResource::ActiveStorage::Reflection::HasManyAttachedReflection)
                attachments = form.submission.data.dig("base", field_name).map{|a|{signed_id:a.signed_id,filename:a.filename}}
                result = attachments
              else
                result = { values_attributes: [{ value: value_in_form[field_name]}]}
              end
              selected_attributes[field_name] = result
            end
          end

          def in_data_base(record, field_name)
            value = !!setting.fields.detect { |t| t.from_id && t.name == field_name && t.from_id == record.id }
          end

          def field
            setting.fields.detect { |t| t.name == field_name }
          end

          def self.fields_attributes(attribute_name, value, update_field = nil, record_for_attachement = nil)
            update_field
          end

          def self.fill_up_selected_attributes
          end

          def self.select_all_by_default?
            false
          end

          def delete_a_record
          end

          def padding
          end

          def self.field_with_same_values?
          end

          private

          def manage_selected_attributes_for_new_record(record)
            if selected_attributes[field_name] && selected_attributes[field_name][:from_id] == record.id
              selected_attributes.delete field_name
            elsif !selected_attributes[field_name]
              selected_attributes[field_name] = {
                from_id: record.id,
                from_type: record.type,
              }
            elsif selected_attributes[field_name] && selected_attributes[field_name][:from_id] != record.id
              selected_attributes[field_name] = {
                from_id: record.id,
                from_type: record.type,
              }
            end
          end

          def manage_selected_attributes_for_persisted_record(record)
            if selected_attributes[field_name] && selected_attributes[field_name][:from_id] == record.id
              selected_attributes[field_name] = {
                destroy: "1",
              }
            elsif selected_attributes.dig(field_name, :destroy)
              selected_attributes[field_name] = {
                from_id: record.id,
                from_type: record.type,
              }
            elsif selected_attributes[field_name] && selected_attributes[field_name][:from_id] != record.id
              selected_attributes[field_name] = {
                from_id: record.id,
                from_type: record.type,
              }
            elsif in_data_base(record, field_name)
              selected_attributes[field_name] = {
                destroy: "1",
              }
            elsif !selected_attributes[field_name]
              selected_attributes[field_name] = {
                from_id: record.id,
                from_type: record.type,
              }
            end
          end
        end

        module Attribute

          class Base < ::Crm::Merge::Setting::Row::Base

            def record_values(record)
              record.send(field_name)
            end

            def handle_record_values_clicked(record)
              TD(class:"cursor-pointer #{"border border-primary" if selected(record, field_name)}", style: { 'padding': padding }) do
                record_values(record, not_selected=false)
              end.on(:click) do |event|
                next if disabled

                if setting.new_record?
                  manage_selected_attributes_for_new_record(record)
                else
                  manage_selected_attributes_for_persisted_record(record)
                end
                click!

                mutate
              end
            end

            def selected_value

              if selected_attributes.dig(field_name, :values_attributes)
                values = selected_attributes.dig(field_name, :values_attributes)[0].dig(:value)
              elsif selected_attributes.dig(field_name, :from_id)
                values = setting.record_to_merges.detect{ |r|r.id == selected_attributes.dig(field_name, :from_id)}
                return values
              elsif selected_attributes.dig(field_name, :destroy)
                return
              elsif field && field.from_type.present?
                value = field.from
                return value
              elsif field && field.name == field_name
                values = field.values[0].value
              end
              setting.result_record_klass.new(field_name => values)
            end

            def self.fields_attributes(attribute_name, value, update_field = nil, record_for_attachement = nil)
              result = {
                name: attribute_name,
                from_id: nil,
                from_type: nil,
              }

              s = super
              if s
                result[:id] = s.id
                if value[:values_attributes].present?
                  detect_value = s&.values&.detect{|v| v.present? }
                  if detect_value
                    result[:values_attributes] = [{id:detect_value.id,value: value[:values_attributes][0][:value]}]
                  else
                    result[:values_attributes] = [{value: value[:values_attributes][0][:value]}]
                  end
                elsif value[:destroy].present?
                  result[:_destroy] = '1'
                else
                  result[:from_id] = value[:from_id]
                  result[:from_type] = value[:from_type]
                end
              else
                if value[:values_attributes].present?
                  result[:values_attributes] = [{value: value[:values_attributes][0][:value]}]
                else
                  result[:from_id] = value[:from_id]
                  result[:from_type] = value[:from_type]
                end
              end
              result
            end

            def selected(record, field_name)
              if selected_attributes[field_name]
                if selected_attributes[field_name][:from_id] == record.id
                  value = true
                elsif selected_attributes[field_name][:destroy] == "1"
                  value = false
                end
              else
                value = in_data_base(record, field_name)
              end
            end

            def self.fill_up_selected_attributes(selected_attributes, record, field_name)
              selected_attributes[field_name] = {
                from_id: record.id,
                from_type: record.type,
              }
            end

            def self.unselect_all_fields(selected_attributes, record, field_name, setting)
              if selected_attributes[field_name]
                if setting.fields.detect{|f|f.name == field_name}
                  selected_attributes[field_name] = {
                    destroy: "1",
                  }
                else
                  selected_attributes.delete(field_name)
                end
              end
            end

            def self.delete_a_record(selected_attributes, record, field_name)
              if selected_attributes[field_name] && selected_attributes[field_name][:from_id] == record.id
                selected_attributes.delete(field_name)
              end
            end

            def self.field_with_same_values?(field_name, setting, available_record_to_merges)
              value_attributes = available_record_to_merges.map {|r| r.send(field_name) }
              return value_attributes.uniq.length == 1
            end
          end

          class DateTime < Base
            def record_values(record)
              moment_format_displayed_value(record.send(field_name))
            end

            def moment_format_displayed_value(v)
              return nil unless v
              m = `moment(#{v})`
              if `#{m}.isValid()`
                result = `#{m}.format(#{display_format})`
                result = nil if result == 'Invalid date'
              end
              return result
            end

            def display_format
              I18n.t('format.date_time')
            end
          end

          class Date < DateTime
            def display_format
              I18n.t('format.date')
            end
          end

          class Enum < Base
            def record_values(record)
              record.class.human_attribute_value(field_name, record.send(field_name))
            end
          end

          class Boolean < Enum
          end

          class Text < Base
            def record_values(record)
              DIV(dangerously_set_inner_HTML: { __html: super}) do
              end
            end
          end

          class TranslatableText < Text
          end
        end

        module Association
          class Base < ::Crm::Merge::Setting::Row::Base; end

          class HasMany < Base

            before_mount do
              @limit = 10
            end

            def padding_top_unnecessary?
              true
            end

            def self.select_all_by_default?
              true
            end

            def record_values(record, not_selected)
              records = record.send(field_name)
              all_checked = checked_all_with_checkbox(selected_attributes, record, field_name)
              TABLE(class: "w-100", style: { "border": "none" }) do
                THEAD do
                  unless not_selected
                    TR do
                      TH(class:"btn btn-light-yiq btn-sm btn-block text-left py-0 cursor-pointer border-0") do
                        I(class:"fa-regular fa-square#{'-check' if all_checked}") do
                        end
                      end.on(:click) do |event|
                        event.stop_propagation
                        if !all_checked
                          self.class.fill_up_selected_attributes(selected_attributes, record, field_name)
                        else
                          self.class.unselect_all_fields(selected_attributes, record, field_name)
                        end
                        mutate
                      end
                    end
                  end
                end
                TBODY do
                  records&.each_with_index do |association, index|
                    next if @limit && index > @limit
                    TR do
                      TD(class: "#{'px-0' if not_selected} #{'border-0' if index == 0 && not_selected} #{selected_association(record, association, index, field_name) unless not_selected}") do
                        DIV do
                          if association.class.name_attribute.present?
                            association.send(association.class.name_attribute)
                          else
                            "#{association.class.name}-#{association.id}"
                          end
                        end
                      end.on(:click) do |event|
                        event.stop_propagation
                        selected_attributes[field_name] ||= []
                        hash = {
                          record: association,
                        }
                        if selected_attributes[field_name].include?(hash)
                          selected_attributes[field_name].delete (hash)
                        elsif field && field.values.detect{|v|v.value[:id] == association.id}
                          selected_attributes[field_name].push({
                            record: association,
                            destroy: "1",
                          })
                        else
                          selected_attributes[field_name].push(hash)
                        end
                        click!
                        mutate
                      end
                    end
                  end
                end
                TFOOT do
                  if records.length > 5
                    TR do
                      TD(class: 'w-100 text-right') do
                        DIV(class: 'btn btn-sm btn-light-yiq') do
                          DIV do
                            @limit ? I18n.t('shared.show_more') : I18n.t('shared.show_less')
                          end
                        end.on(:click) do |event|
                          event.stop_propagation
                          @limit = @limit ? nil : 10
                          mutate
                        end
                      end
                    end
                  end
                end
              end
            end

            def fake_header
              TABLE(class: "w-100 border-0") do
                THEAD do
                  TR(class: 'bg-light') do
                    TH(class:"btn btn-sm btn-block text-left py-0 border-0") do
                      I(class: 'fa')
                    end
                  end
                end
                TBODY do
                  TR do
                    yield
                  end
                end
              end
            end

            def field_name_label
              TD(class: 'p-0') do
                fake_header do
                  super
                end
              end
            end


            def handle_record_values_clicked(record)
              TD(class:"cursor-pointer #{"border border-primary" if selected(record, field_name)}", style: { 'padding': padding }) do
                record_values(record, not_selected=false)
              end
            end

            def display_selected_value
              TD(class: 'p-0') do
                fake_header do
                  super
                end
              end
            end

            def selected_value
              records = []

              if selected_attributes.dig(field_name).is_a?(Array)
                records = selected_attributes.dig(field_name).map do|v|
                  next if v[:destroy].present?
                  v[:record]
                end
              elsif selected_attributes.dig(field_name, :values_attributes)
                ids = selected_attributes.dig(field_name, :values_attributes).map { |v| v[:value_id] }
                observe models = setting.result_record_klass.reflect_on_association(field_name).klass.where(id: ids).all
                records = models
              elsif field && field.name == field_name
                field.values.each do |f|
                  records << f.value
                end
              end
              a = setting.result_record_klass.new(field_name => records)
              return a
            end

            def selected_association(record, association, index, field_name)
              if selected_attributes[field_name]
                result = selected_attributes.dig(field_name).detect { |a|
                  next if a[:destroy].present?
                  a[:record].id == association.id
                }
                if result
                  return "border border-primary"
                end
              elsif field && field.values.detect{|v|v.value[:id] == association.id}
                return "border border-primary"
              end
            end

            def self.fill_up_selected_attributes(selected_attributes, record, field_name)
              selected_attributes[field_name] ||=[]
              record.send(field_name).each do |r|
                next if selected_attributes[field_name].include?({record:r})
                selected_attributes[field_name].push({record:r})
              end
            end

            def self.unselect_all_fields(selected_attributes, record, field_name)
              ids = record.send(field_name).map{ |r| r.id}
              selected_attributes[field_name].select! { |f| !ids.include?(f[:record].id) }
            end

            def checked_all_with_checkbox(selected_attributes, record, field_name)
              if selected_attributes.dig(field_name).is_a?(Array)
                field_ids = selected_attributes.dig(field_name).map{|a|a[:record].id}
                record_ids = record.send(field_name).map{|r|r.id}
                result = record_ids.all? { |element| field_ids.include?(element) }
                if result
                  return true
                end
              else
                return false
              end
            end

            def self.fields_attributes(attribute_name, value, update_field = nil, record_for_attachement = nil)
              value_record = []
              s = super
              value.each do |r|
                detect_value = s&.values&.detect{|t|t.value[:id] == r[:record].id }

                if r[:destroy].present?
                  value_record << {
                    id: detect_value.id,
                    _destroy: '1'
                  }
                elsif detect_value
                  value_record << {
                    id: detect_value.id,
                    value_type: r[:record].type,
                    value_id:r[:record].id
                  }
                else
                  value_record << {
                    value_type: r[:record].type,
                    value_id:r[:record].id
                  }
                end
              end

              result = {
                name: attribute_name,
                from_id: nil,
                from_type: nil,
                values_attributes: value_record,
              }

              if s.present?
                result[:id] = s.id
              end
              result
            end

            def self.delete_a_record(selected_attributes, record, field_name)
              if selected_attributes[field_name]
                ids = record.send(field_name).map{|r|r.id}
                fields = []
                selected_attributes[field_name].each do |r|
                  if !ids.include?(r[:record].id)
                    fields.push(r)
                  end
                end
                selected_attributes[field_name] = fields
              end
            end

            def padding
              return 0
            end

            def self.field_with_same_values?(field_name, setting, available_record_to_merges)
              association_ids = {}
              available_record_to_merges.each {|r| association_ids[r.id] = r.send(field_name).map(&:id) }
              return association_ids.values.uniq.length == 1
            end
          end
          class BelongsTo < Base
            def record_values(record)
              associated_record = record.send(field_name)
              associated_record&.send(associated_record&.class&.name_attribute)
            end

            def handle_record_values_clicked(record)
              TD(class:"cursor-pointer #{"border border-primary" if selected(record, field_name)}", style: { 'padding': padding }) do
                record_values(record, not_selected=false)
              end.on(:click) do |event|
                next if disabled

                if setting.new_record?
                  manage_selected_attributes_for_new_record(record)
                else
                  manage_selected_attributes_for_persisted_record(record)
                end
                click!

                mutate
              end
            end

            def selected_value
              if selected_attributes.dig(field_name, :from_id)
                a = setting.record_to_merges.detect { |r| r.id == selected_attributes.dig(field_name, :from_id)}
                return a
              elsif selected_attributes.dig(field_name, :values_attributes)
                record_id = selected_attributes.dig(field_name, :values_attributes)[0].dig(:value_id)
                observe model = setting.result_record_klass.reflect_on_association(field_name).klass.where(id: record_id).first
                a = model
              elsif selected_attributes.dig(field_name, :destroy)
                return
              elsif field && field.from_type.present?
                a = field.from
                return a
              elsif field && field.name == field_name
                a = field.values[0].value
              end
              setting.result_record_klass.new(field_name => a)
            end

            def self.fields_attributes(attribute_name, value, update_field = nil, record_for_attachement = nil)
              result = {
                name: attribute_name,
                from_id: nil,
                from_type: nil,
              }

              s = super
              if s
                result[:id] = s.id
                if value[:values_attributes].present?
                  detect_value = s&.values&.detect{|v| v.present? }
                  if detect_value
                    result[:values_attributes] = [{id:detect_value.id, value_id: value[:values_attributes][0][:value_id], value_type: value[:values_attributes][0][:value_type]}]
                  else
                    result[:values_attributes] = [{value_id: value[:values_attributes][0][:value_id],value_type: value[:values_attributes][0][:value_type]}]
                  end
                elsif value[:destroy].present?
                  result[:_destroy] = '1'
                else
                  result[:from_id] = value[:from_id]
                  result[:from_type] = value[:from_type]
                end
              else
                if value[:values_attributes].present?
                  result[:values_attributes] = [{value_id: value[:values_attributes][0][:value_id],value_type: value[:values_attributes][0][:value_type]}]
                else
                  result[:from_id] = value[:from_id]
                  result[:from_type] = value[:from_type]
                end
              end
              result
            end

            def selected(record, field_name)
              if selected_attributes[field_name]
                if selected_attributes[field_name][:from_id] == record.id
                  value = true
                elsif selected_attributes[field_name][:destroy] == "1"
                  value = false
                end
              else
                value = in_data_base(record, field_name)
              end
            end

            def self.fill_up_selected_attributes(selected_attributes, record, field_name)
              selected_attributes[field_name] = {
                from_id: record.id,
                from_type: record.type,
              }
            end

            def self.unselect_all_fields(selected_attributes, record, field_name, setting)
              if selected_attributes[field_name]
                if setting.fields.detect{|f|f.name == field_name}
                  selected_attributes[field_name] = {
                    destroy: "1",
                  }
                else
                  selected_attributes.delete(field_name)
                end
              end
            end

            def self.delete_a_record(selected_attributes, record, field_name)
              if selected_attributes[field_name] && selected_attributes[field_name][:from_id] == record.id
                selected_attributes.delete(field_name)
              end
            end

            def self.field_with_same_values?(field_name, setting, available_record_to_merges)
              value_attributes_ids = available_record_to_merges.map {|r| r.send(field_name)&.id }
              return value_attributes_ids.uniq.length == 1
            end
          end

        end

        module Attachment
          class Base < ::Crm::Merge::Setting::Row::Base
            def photo_tag(record ,fallback_icon)
              signed_id = record&.attachment&.signed_id
              @photo_errors ||= {}
              if signed_id && !@photo_errors[signed_id]
                IMG({
                  src: "#{::HyperResource::Base.api_prefix}/files/representations/#{signed_id}/photo-button/photo.png",
                  class: "photo-button mr-1",
                })
              end
            end

            def handle_record_values_clicked(record)
              TD(class:"cursor-pointer #{"border border-primary" if selected(record, field_name)}", style: { 'padding': padding }) do
                record_values(record, not_selected=false)
              end.on(:click) do |event|
                next if disabled

                if setting.new_record?
                  manage_selected_attributes_for_new_record(record)
                else
                  manage_selected_attributes_for_persisted_record(record)
                end
                click!

                mutate
              end
            end
          end
          class HasOneAttached < Base
            def record_values(record)
              attachment = record.send(field_name)
              photo_tag(attachment, record&.class.try(:icon))
            end

            def selected_value
              if selected_attributes.dig(field_name, :from_id)
                result = setting.record_to_merges.detect { |r| r.id == selected_attributes.dig(field_name, :from_id) }
                return result
              elsif selected_attributes.dig(field_name, :values_attributes)
                signed_id = selected_attributes.dig(field_name,:values_attributes)[0][:value]
                photo_upload = {"attachment"=>{"signed_id"=> signed_id, "filename"=> @filename}}
                result = setting.result_record_klass.new(field_name => photo_upload)
                return result
              elsif field
                result = setting.result_record_klass.new(field_name => field.values[0]&.value&.except("attachments"))
                return result
              end
              setting.result_record_klass.new
            end

            def self.fields_attributes(attribute_name, value, update_field = nil, record_for_attachement = nil)
              result = {
                name: attribute_name,
                from_id: nil,
                from_type: nil,
              }

              if update_field.present?
                result[:id] = update_field.id

                if value[:values_attributes].present?
                  signed_id = value[:values_attributes][0][:value]
                  detect_value = update_field&.values&.detect{|v| v.present? }
                  result[:values_attributes] = [{
                    id: detect_value.id,
                    value: signed_id,
                  }]
                else
                  signed_id = record_for_attachement.send(attribute_name)&.attachment&.signed_id
                  detect_value = update_field&.values&.detect{|v| v.present? }

                  result[:from_id] = value[:from_id]
                  result[:from_type] = value[:from_type]
                  result[:values_attributes] = [{
                    id: detect_value.id,
                    value: signed_id,
                  }]
                end
              else
                if value[:values_attributes].present?
                  signed_id = value[:values_attributes][0][:value]

                  result[:values_attributes] = [{
                    value: signed_id,
                  }]
                else
                  signed_id = record_for_attachement.send(attribute_name)&.attachment&.signed_id

                  result[:from_id] = value[:from_id]
                  result[:from_type] = value[:from_type]
                  result[:values_attributes] = [{
                    value: signed_id,
                  }]
                end
              end
              result
            end

            def selected(record, field_name)
              if selected_attributes[field_name]
                if selected_attributes[field_name][:from_id] == record.id
                  value = true
                elsif selected_attributes[field_name][:destroy] == "1"
                  value = false
                end
              else
                value = in_data_base(record, field_name)
              end
            end

            def self.fill_up_selected_attributes(selected_attributes, record, field_name)
              selected_attributes[field_name] = {
                from_id: record.id,
                from_type: record.type,
              }
            end

            def self.unselect_all_fields(selected_attributes, record, field_name)
              selected_attributes.delete(field_name)
            end

            def self.delete_a_record(selected_attributes, record, field_name)
              if selected_attributes[field_name] && selected_attributes[field_name][:from_id] == record.id
                selected_attributes.delete(field_name)
              end
            end

            def self.field_with_same_values?(field_name, setting, available_record_to_merges)
              value_attributes = available_record_to_merges.map {|r| r.send(field_name)&.attachment&.signed_id }
              return value_attributes.uniq.length == 1
            end
          end
          class HasManyAttached < Base

            def self.select_all_by_default?
              true
            end

            def record_values(record, not_selected)
              TABLE(class: "w-100", style: { "border": "none" }) do
                TBODY do
                  record&.send(field_name)&.attachments&.to_a&.each_with_index do |attachment, index|
                    TR do
                      TD(class: "#{ 'border-0' if index == 0 && not_selected} #{selected_association(record, attachment, index, field_name) unless not_selected}", style: { 'wordWrap': "break-word", 'width': 200}) do
                        attachment.filename
                      end.on(:click) do
                        selected_attributes[field_name] ||= []
                        hash = {
                          signed_id: attachment.signed_id,
                          filename: attachment.filename,
                        }
                        if selected_attributes[field_name].include?(hash)
                          selected_attributes[field_name].delete(hash)
                        else
                          selected_attributes[field_name].push(hash)
                        end
                        click!
                        mutate
                      end
                    end
                  end
                end
              end
            end

            def selected_value
              if selected_attributes.dig(field_name)
                attachments = selected_attributes.dig(field_name)
                result = setting.result_record_klass.new(field_name => {attachments: attachments})
                return result
              elsif field
                attachments = []
                field.values.each do |v|
                  attachments << v.value[:attachments][0]
                end
                result = setting.result_record_klass.new(field_name => {attachments: attachments})
                return result
              end
              setting.result_record_klass.new
            end

            def self.fields_attributes(attribute_name, value, update_field = nil, record_for_attachement = nil)
              result = {
                name: attribute_name,
                from_id: nil,
                from_type: nil,
              }
              if update_field.present?
                result[:id] = update_field.id
                update_field.values.each do |value_in_base|
                  value.each do |value_in_selected|
                    selected = value_in_selected[:signed_id]
                    if value_in_base.value[:attachments][0][:signed_id] == selected
                      result[:values_attributes] = [{
                        id: value_in_base.id,
                        value: selected,
                      }]
                    else
                      result[:values_attributes] = [{
                        value: selected,
                      }]
                    end
                  end
                end
              else
                result[:values_attributes] = value.map { |v| {value:v[:signed_id]} }
              end
              result
            end

            def selected_association(record, association, index, field_name)
              value = nil
              if selected_attributes[field_name]
                if selected_attributes[field_name].is_a?(Array)
                  if selected_attributes.dig(field_name).detect{|a| a[:signed_id] == association.signed_id}
                    return "border border-primary"
                  elsif index == 0
                    return "border-0"
                  end
                elsif selected_attributes[field_name][:destroy] == "1"
                  value = false
                end
              elsif field && field.values.detect{|v|v.value[:attachment][:signed_id] == association.signed_id}
                return "border border-primary"
              elsif index == 0
                return "border-0"
              end
            end

            def self.fill_up_selected_attributes(selected_attributes, record, field_name)
              selected_attributes[field_name] ||=[]
              record.send(field_name)&.attachments.each do |a|
                attachement = { signed_id: a.signed_id, filename: a.filename }
                next if selected_attributes[field_name].include?(attachement)
                selected_attributes[field_name].push(attachement)
              end
            end

            def self.unselect_all_fields(selected_attributes, record, field_name)
              attachments = record.send(field_name)&.attachments.map{ |a| {
                signed_id: a.signed_id,
                filename: a.filename,
              }}
              selected_attributes[field_name].select! { |f| !attachments.include?(f) }
            end

            def self.delete_a_record(selected_attributes, record, field_name)
              if selected_attributes[field_name]
                ids = record.send(field_name)&.attachments.map{|a|a.signed_id}
                fields = []
                selected_attributes[field_name].each do |r|
                  if !ids.include?(r[:signed_id])
                    fields.push(r)
                  end
                end
                selected_attributes[field_name] = fields
              end
            end

            def padding
              return 0
            end

            def self.field_with_same_values?(field_name, setting, available_record_to_merges)
              association_ids = {}
              available_record_to_merges.each {|r| association_ids[r.id] = r.send(field_name)&.attachments.map(&:signed_id) }
              return association_ids.values.uniq.length == 1
            end
          end
        end

        class Type < Attribute::Base
          def record_values(record)
            k = record.send(field_name)
            k&.safe_constantize&.model_name&.human || k&.demodulize
          end
        end
      end

    end
  end
end
