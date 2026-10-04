class Form
  module Element
    module Association
      class HasMany < Base

        param :value_position, default: nil
        param :show_value, default: true
        render { content }

        def association_name
          return attribute_name unless attribute_name.end_with?('_ids')
          return attribute_name.gsub(/_ids$/, '').pluralize
        end

        def input_name
          "#{super}[]"
        end

        def record_association_attributes
          if record
            associated_records = record.new_record? ? default_records : record.send(association_name)

            if !orderable_association? && associated_records
              # sort by id because postgresql can return unordered associations
              associated_records = associated_records.sort_by{|a| a.id || uuid_max }
            end

            result = associated_records&.map do |r|
              record_attributes(r)
            end
          end

          result ||= []

          if association_min
            new_position = form.submission.new_position(path) if orderable_association?
            result.fill(result.length, association_min - result.length) do
              r = attrs_for_new_record.dup
              if orderable_association?
                r[:position] = new_position
                new_position += 1
              end
              r
            end
          end

          return result
        end

        # on a new record: the form default wins over the schema default
        def default_records
          form_default_records = (other_params[:default_value] || []).to_a
          return form_default_records if form_default_records.any?
          (record.send(association_name) || []).to_a
        end

        def uuid_max
          'FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF'
        end

        def orderable_association?
          !!target_klass&.attributes&.dig('position')
        end

        def change_value(value)
          return super if attribute_name.end_with?('_ids') || attribute_name.end_with?('_id')

          return unless form && !form.reseting?
          old_value = form.submission.read_association(path)
          new_value = convert_value(value)
          if new_value != old_value
            form.enable
            new_value = manage_values_to_destroy(old_value, new_value)
            form.submission.write_association(path, new_value)
            form.submission.write_association_values(path, new_value)
            change_data(value)
            mutate
            change!(value, form, self)
            form.change
          end
        end

        def manage_values_to_destroy(old_value, new_value)
          return new_value unless old_value

          result = []
          old_value.each do |o|
            v = new_value&.detect{|v| o == v}
            if v
              result << v
            else
              result << o.merge(_destroy: 1)
            end
          end

          new_value.each do |v|
            result << v unless result.include?(v)
          end

          return result
        end


        def convert_value(value)
          if attribute_name.end_with?('_ids')
            convert_value_to_id(value)
          else
            return value unless value.is_a?(Array) || value.is_a?(HyperResource::Relation)
            return value.compact.map do |e|
              if polymorphic?
                { 'id' => e.id, 'type' => e.type }
              else
                { 'id' => e.id }
              end
            end
          end
        end

        def convert_value_to_id(value)
          return value unless value.is_a?(Array)
          return value.compact.map do |a|
            if id?(a)
              a
            else
              if polymorphic?
                if a.is_a?(Hash)
                  a # slice id and type ?
                else
                  { 'id' => a.id, 'type' => a.type }
                end
              else
                if a.is_a?(Hash)
                  a['id']
                else
                  a.id
                end
              end
            end
          end
        end

        # input ------------------------------------------------------------------

        def select_args
          super.merge({
            defaultValue: selected_values.map{|v| v[:value]},
            multiple: true,
          })
        end

        def selected_values
          return [] unless form
          return form.submission.read_ids(path).map do |id|
            d = form.submission.data.dig(input_prefix, attribute_name)&.detect{|a| a.id == id }
            { value: id, label: record_name(d) }
          end
        end

        def self.tom_select_options(target_klass, target_klass_url, css_class = nil, autocomplete_variables_proc = nil, cache_items_proc = nil)
          return super.merge({
            plugins: {
              virtual_scroll: {},
              remove_button: { # add remove buttons on items
                title: I18n.t('shared.delete'),
              }
            },
          })
        end

        # edit in place -------------------------------------------------------------------

        def render_edit_in_place_not_editing
          edit_in_place_fake_input do
            edit_in_place_value_container do
              values = record.send(association_name)
              if values&.any?
                edit_in_place_list_group do
                  values.each do |e|
                    LI(class: 'pb-2 text-truncate', title: record_name(e), style: { flexShrink: 0 }) do # intentionnally not a list-group-item
                      render_item(e)
                    end
                  end
                end
              else
                placeholder
              end
            end
          end.on(:click) do |event|
            event.prevent_default
            @edit = true
            mutate
          end
        end

        def edit_in_place_list_group
          UL(class: 'list-group border-0', style:{ height: '100%', maxHeight: '50vh', overflowY: 'auto' }) do
            yield
          end
        end

        def edit_in_place_input_args
          result = {
            id: edit_in_place_input_id,
            class: "form-control #{invalid_css_class}",
          }
          result[:disabled] = "disabled" if disabled
          result[:readonly] = "readonly" if readonly
          result[:"aria-describedby"] = "help-#{form_group_id}" if help.present?
          return result
        end

        def edit_in_place_fake_input
          DIV(class: "form-control #{css_classes&.dig(:field_size)} px-0 cursor-text bg-transparent", style:{ height: '100%'}) do
            yield
            edit_in_place_icon(right: 20, top: 5, zIndex: 10000)
          end
        end

        def edit_in_place_value_container
          yield
        end

        def render_edit_in_place_editing
          DIV(class: 'px-0 mt-2') do
            values = record.send(association_name)
            if values.any?
              edit_in_place_list_group do
                values.each do |e|
                  LI(class: 'list-group-item d-flex justify-content-between align-items-center text-break') do
                    render_item(e)
                    remove_btn(e)
                  end
                end
              end
            end
            search_input_for_add_item
          end
        end

        def remove_btn(e)
          A(href: "#remove", class: "btn btn-light btn-sm float-right #{'disabled' if disabled}") do
            I(class: 'fas fa-trash') do
            end
          end.on(:click) do |event|
            event.prevent_default
            next if self.disabled
            @original_value = record.send(association_name)
            remove_association_element(e)
            mutate
          end
        end

        def search_input_for_add_item
          InputWithAutocomplete({
            input_args: edit_in_place_input_args,
            search_url: target_klass_search_url,
            template_result: self.class.template_result_ruby(target_klass),
            process_params: Proc.new { |params| add_autocomplete_variables_to_params(params) },
            autofocus: false,
            class: 'mt-2',
          }).on(:focus) do |event|
            @original_value = record.send(association_name)
          end.on(:blur) do |event|
          end.on(:key_enter) do |event, value|
            append_association_element(selected_record(value))
          end.on(:key_escape) do |event|
            @edit = false
            mutate
          end.on(:select) do |event, value|
            append_association_element(selected_record(value))
          end
        end

        def append_association_element(e)
          value = record.send(association_name) + [e]
          edit_in_place_submit_value(value) do |response|
            edit_in_place_scroll_to_element(e) if response[:success]
          end
        end

        def remove_association_element(e)
          value = record.send(association_name)
          value = value.select{|v| v.id != e.id}
          edit_in_place_submit_value(value)
        end

        def edit_in_place_scroll_to_element(element)
          after(0.1) do
            ::Element.find(dom_node).find('.list-group').scrollTop(10000)
          end
        end

        def attribute_name_for_update
          attribute_name.end_with?('_ids') ? attribute_name : "#{attribute_name.singularize}_ids"
        end

        # checkbox ---------------------------------------------------------------

        def render_input_checkbox_inline
          render_input_checkbox(true)
        end

        def render_input_checkbox(inline = false)
          layout_input do
            if value_position == 'top' && inline == true
              DIV(class: 'text-left') do
                render_possible_values_or_records_top(inline) do |id, value|
                  input_checkbox(id, value)
                end
              end
            elsif value_position == 'top' && inline == false
              render_possible_values_or_records_top(inline) do |id, value|
                input_checkbox(id, value)
              end
            elsif (value_position == 'right' || value_position.nil?) && inline == true
              DIV(class: 'text-left') do
                render_possible_values_or_records_right(inline) do |id, value|
                  input_checkbox(id, value)
                end
              end
            elsif (value_position == 'right' || value_position.nil?) && inline == false
              render_possible_values_or_records_right(inline) do |id, value|
                input_checkbox(id, value)
              end
            end
          end
        end

        def input_checkbox(id, value)
          INPUT(input_checkbox_args.merge(id: id, checked: checked?(value), value: value.id)).on(:change) do |event|
            manage_values_associations_clicked(value, event.current_target.checked)
          end
        end

        def render_possible_values_or_records_right(inline)
          possible_values_or_records.each_with_index do |possible_value_or_record, i|
            id = value_id(i)
            DIV(class: "form-check #{inline ? 'form-check-inline' : ''}") do
              value = possible_value_or_record[:value] ? possible_value_or_record[:value] : possible_value_or_record
              label = render_label(possible_value_or_record)
              yield(id, value)
              LABEL(class: 'form-check-label', htmlFor: id) do
                show_value ? label : ''
              end
            end
          end
        end

        def render_possible_values_or_records_top(inline)
          possible_values_or_records.each_with_index do |possible_value_or_record, i|
            id = value_id(i)
            DIV(class: "form-check #{inline ? 'form-check-inline' : ''}") do
              value = possible_value_or_record[:value] ? possible_value_or_record[:value] : possible_value_or_record
              label = render_label(possible_value_or_record)
              SPAN(class: "text-center") do
                LABEL(class: '', htmlFor: id) do
                  DIV(class: show_value ? 'no-height' : '') do # TODO class no-height
                    show_value ? label : ''
                  end
                  yield(id, value)
                end
              end
            end
            LABEL(class: '') do
              ''
            end
          end
        end

        def manage_values_associations_clicked(record_clicked, is_checked)
          values = form.submission.read_association(path) || []
          values_data = form.submission.data[input_prefix][attribute_name] || []
          checked_values = []
          values.each do |val|
            already_checked_data = values_data.detect {|da| da.id == val[:id] }
            next unless already_checked_data
            if already_checked_data.id == record_clicked.id
              if is_checked
                checked_values << already_checked_data
              end
            else
              checked_values << already_checked_data
            end
          end
          if is_checked && !checked_values.include?(record_clicked)
            checked_values << record_clicked
          end
          checked_values_relation = HyperResource::Relation.new(record_clicked.class, association: record.association(association_name), records: checked_values)
          change_value(checked_values_relation)
        end

        def checked?(pv)
          ids = form&.submission&.read_ids(path)
          return !!ids&.detect{|id| id == pv[:value].id} if pv[:value]
          return !!ids&.detect{|id| id == pv.id}
        end

        def input_checkbox_args
          result = {
            name: input_name,
            type: 'checkbox',
            class: "form-check-input #{invalid_css_class}",
          }
          result[:disabled] = "disabled" if disabled
          result[:readonly] = "readonly" if readonly
          result[:"aria-describedby"] = "help-#{form_group_id}" if help.present?
          return result
        end

        # read only ---------------------------------------------------------------

        def read_only_displayed_value
          value = record.send(association_name)
          return unless value&.any?
          value.each do |v|
            render_item(v)
            BR{}
          end
        end

        # ---------------------------------------------------------------

      end
    end
  end
end
