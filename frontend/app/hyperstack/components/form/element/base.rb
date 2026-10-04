# backtick_javascript: true

require 'components/form'

class Form
  module Element
    class Base < HyperComponent
      include UrlHelper

      param :form, default: nil
      param :editor, default: nil
      param :compact, default: false

      param :record, default: nil

      param :prefix_path, default: nil
      param :attribute_name, default: nil

      param :label, default: nil
      param :text, default: nil
      param :value, default: nil

      param :css_classes, default: nil

      param :disabled, default: false
      param :readonly, default: false
      param :help, default: nil
      param :help_position, default: 'bottom'
      param :placeholder, default: nil
      param :requirement, default: nil
      param :errors_from, default: nil
      param :auto_focus, default: false
      param :in_editor, default: false
      param :same_as_id, default: nil
      param :show_label, default: true
      param :force_default_value, default: false
      param :in_hash, default: nil
      param :valid, default: true

      param :conditions, default: []
      param :condition_formula, default: nil

      param :autocomplete_filters, default: nil

      param :timestamp, default: nil

      collect_other_params_as :other_params

      fires :change

      render { content }

      def content
        send(:"render_#{mode}")
      end

      def render_diff
      end

      def render_input
      end

      def render_edit_in_place
      end

      def render_readonly
      end

      def render_edit_cell
      end

      private

      def mode
        other_params[:mode] || form&.dynamic_form&.mode || :input
      end

      def input_prefix
        return unless prefix_path
        return compute_input_prefix(prefix_path)
      end

      def compute_input_prefix(input_prefix)
        if form.dynamic_form

          r = []
          prefix_path.each_with_index do |p, i|
            if i == 0
              r << p
            elsif prefix_path[i + 1].is_a?(Integer)
              r << "#{p}@#{prefix_path[i + 1]}"
            end
          end
          result = r.join('.')

        else

          r = []
          prefix_path.each_with_index do |p, i|
            if i == 0
              r << p
            elsif prefix_path[i + 1].is_a?(Integer)
              r << "[#{p}_attributes]"
            else
              r << "[#{p}]"
            end
          end
          result = r.join

        end

        return result
      end

      def path
        return [] unless prefix_path
        return prefix_path + [attribute_name]
      end

      ID_REGEXP = /(?:^\d+$)|(?:^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$)/

      def id?(v)
        v.is_a?(Integer) || (v.is_a?(String) && v =~ ID_REGEXP)
      end

      def placeholder_
        if !show_label && ['important', 'mandatory'].include?(requirement)
          # can't be done properly in css: ::placeholder:after doesn't work
          placeholder.present? ? [placeholder, '*'].join(' ') : '*'
        else
          placeholder.present? ? placeholder : nil
        end
      end

      # layouts ----------------------------------------------------------------------

      def layout_input
        DIV(ref: _ref, class: "row form-group #{requirement} #{other_params[:className]}", style: other_params[:style]) do
          if show_label
            LABEL(class: "#{label_col_size} col-form-label control-label #{css_classes&.dig(:label_size)}", htmlFor: input_id) do
              if help.present? && help_position == 'icon'
                SPAN do
                  displayed_label
                end
                icon_help
              else
                displayed_label
              end
            end
          end
          DIV(class: input_col_size) do
            if help.present? && help_position == 'top'
              small_help
            end
            if help.present?
              if help_position == 'bottom'
                yield
                small_help
              elsif help_position == 'icon' && !show_label
                yield
                DIV(class: 'd-flex flex-row') do
                  icon_help
                end
              else
                yield
              end
            else
              yield
            end
          end
        end
      end

      def icon_help
        I(class: 'fa fa-fw fa-question-circle p-2 align-self-center', 'data-toggle': 'tooltip', title: help, "data-html": true)
        after(0.1) do
          jq_node.find('[data-toggle="tooltip"]').tooltip('dispose')
          jq_node.find('[data-toggle="tooltip"]').tooltip()
        end
      end

      def small_help
        SMALL(class: "form-text", dangerously_set_inner_HTML: { __html: help })
      end

      def layout_edit_in_place
        DIV(ref: _ref, class: "row form-group #{requirement} edit-in-place mb-1") do
          if show_label
            LABEL(class: "#{label_col_size} font-weight-bold control-label #{css_classes&.dig(:label_size)} mb-0 pt-2") do
              displayed_label
            end.on(:click) do |event|
              @edit = true
              mutate
            end
          end
          DIV(class: input_col_size) do
            if help.present?
              P(id: "help-#{form_group_id}", class: "help-block") do
                help
              end
            end
            yield
          end
        end
      end

      def layout_input_hidden
        DIV(ref: _ref, class: "row form-group #{requirement}", style: {opacity: 0.5}) do
          LABEL(class: "#{label_col_size} control-label #{css_classes&.dig(:label_size)}", htmlFor: input_id) do
            displayed_label
          end
          DIV(class: input_col_size) do
            yield
          end
        end
      end

      def displayed_label
        return label || (other_params[:label_attribute] && record&.send(other_params[:label_attribute])) || record_klass&.human_attribute_name(attribute_name)&.capitalize
      end

      def record_klass
        record&.class || other_params[:klass_name]&.safe_constantize
      end

      def layout_read_only_compact
        v = form.submission.read(path)
        return if (v.nil? || v == '') && !in_editor

        DIV(ref: _ref, class: "form-group mb-2") do
          if show_label || in_editor
            LABEL(class: "form-label mb-0 font-weight-bold text-dark #{css_classes&.dig(:label_size)}") do
              displayed_label
            end
          end
          DIV(class: "#{css_classes&.dig(:field_size)}") do  # use col-form-label in order to be vertically aligned with label
            read_only_value_container do
              yield
            end
          end
        end
      end

      def layout_read_only_responsive
        v = form.submission.read(path)
        return if (v.nil? || v == '') && !in_editor

        DIV(ref: _ref, class: "row") do
          if show_label || in_editor
            LABEL(class: "#{label_col_size} col-form-label font-weight-bold text-dark #{css_classes&.dig(:label_size)}") do
              displayed_label
            end
          end
          DIV(class: "#{input_col_size} col-form-label #{css_classes&.dig(:field_size)}") do  # use col-form-label in order to be vertically aligned with label
            read_only_value_container do
              yield
            end
          end
        end
      end

      def layout_edit_cell
        DIV(class: 'edit-in-place') do
          yield
        end
      end

      def read_only_value_container
        yield
      end

      def layout_diff
        layout_readonly do
          yield
        end
      end

      def render_read_only
        if compact.blank? || compact == false
          render_read_only_responsive
        elsif compact == true
          render_read_only_compact
        end
      end

      def render_read_only_compact
        layout_read_only_compact do
          read_only_displayed_value
        end
      end

      def render_read_only_responsive
        layout_read_only_responsive do
          read_only_displayed_value
        end
      end

      def read_only_displayed_value
      end

      # edit in place -------------------------------------------------------------------

      def edit_in_place_fake_input
        DIV(class: "form-control #{css_classes&.dig(:field_size)} px-0 cursor-text bg-transparent") do
          yield
          edit_in_place_icon
        end
      end

      def edit_in_place_value_container
        SPAN(class: "d-inline-block", style: {maxWidth: 'calc(100% - 20px)'}) do
          yield
        end
      end

      def edit_in_place_icon(s = {right: 0, top: 0, zIndex: 10000})
        return if @mouse_hover_link
        EditInPlaceIcon(
          loading: @loading,
          success: @success,
          style: s,
          error_message: (@success == false ? input_errors_for_popover : nil)
        )
        if @success == true
          after(3) do
            if @success == true
              @success = nil
              mutate
            end
          end
        end
      end

      def edit_in_place_editing_input
        ::Element.find(dom_node).find('input.form-control')
      end

      def focus_edit_in_place_editing_input
        edit_in_place_editing_input.focus
      end

      def edit_in_place_editing?
        return false unless form&.mode == :edit_in_place
        if @edit.nil?
          @edit = other_params[:editing]
        end
        @edit
      end

      def compute_edit_change
        if (form&.mode != :edit_in_place) # should be somewhere else
          @edit = true
          @edit_changed = false
          return
        end
        @edit_changed = (@edit_was != @edit)
        @edit_was = @edit
      end

      def edit_changed?
        @edit_changed
      end

      def around_edit_in_place_submit_value
        @edit_in_place_submit_options = {}
        @edit_in_place_submit_options.merge!(form.additional_submit_options)
        if form.dynamic_form
          @edit_in_place_submit_options[:versioning] = {
            source_type: 'Dynamic::Form',
            source_id: form.dynamic_form.id,
          }
        end
        yield
      end

      def empty_and_show_placeholder?
        form.submission.read(path).blank?
      end

      # Autocomplete  -------------------------------------------------------------------

      def autocomplete_variables_proc
        @autocomplete_variables_proc ||= Proc.new { determine_autocomplete_variable_values }
      end

      def determine_autocomplete_variable_values
      end

      def self.extract_variables(filters, result = [])
        case filters
        when ::Hash
          if filters[:variable]
            result << filters[:variable]
          else
            filters.each do |k, v|
              extract_variables(v, result)
            end
          end
        when ::Array
          filters.each do  |e|
            extract_variables(e, result)
          end
        end
        return result
      end

      def extract_variables(filters, result = [])
        self.class.extract_variables(filters, result)
      end

      def autocomplete_filters_result
        return unless autocomplete_filters
        return @autocomplete_filters_result if @autocomplete_filters_result
        @autocomplete_filters_result = autocomplete_filters.is_a?(Proc) ? autocomplete_filters.call(form) : autocomplete_filters
        @autocomplete_filters_result
      end

      def add_autocomplete_filters_to_params(params)
        if autocomplete_filters_result.present?
          params[:filters] = Rison.dump(autocomplete_filters_result)
          add_autocomplete_variables_to_params(params)
        end
        return params
      end

      def add_autocomplete_variables_to_params(params)
        variables = autocomplete_variables_proc&.call
        params[:variables] = variables if variables&.any?
        return params
      end

      def add_order_to_params(params)
        if other_params[:sorting_attribute].present?
          params.merge!(sort: other_params[:sorting_attribute], dir: other_params[:sorting_type] || 'asc')
        end
        return params
      end

      # ---------------------------------------------------------------------------------

      after_new_params do
        init_submission_params
        init_condition_attrs_to_clean
        compute_edit_change
      end

      def init_submission_params(record = self.record, prefix_path = self.prefix_path)
        return unless record && form&.submission

        attribute_names.each do |attr|
          next unless attr
          path = prefix_path + [attr]
          value = self.value # from component param

          if value.nil?
            next if form.submission.has_key?(path)
            if in_hash && prefix_path&.any?
              value = record.send(prefix_path[1])
              value = value.dig(*path[2..-1]) if value.is_a?(::Hash)
            else
              value = record.send(attr)
            end
            # on a new record, a value may come from the schema default: the form default wins
            default_value = other_params[:default_value]
            value = default_value if value.nil? || forced_default_value? || (record.new_record? && default_value.present?)
          end
          form.submission.write_from_db(path, convert_value(value))
          if record.persisted? && path.length > 3
            p = path[0..-2] + ['id']
            unless form.submission.has_key?(p)
              form.submission.write_from_db(p, record.id)
              # TODO if parent element is a nested form for a polymorphic association
            end
          end

          change_data(value, record) if attr == attribute_name
        end

        init_position
      end

      def mutations(_objects) # prevent stupid rerender when form.mutate (TODO investigate why mutate form do that)
        return if _objects.first.class == ::Form
        super
      end

      def init_position
        return unless prefix_path.length > 2
        a = form.submission.read_association(prefix_path[0..-2])
        position = a&.dig(prefix_path.last, :position)
        p = prefix_path + [:position]
        if position && !form.submission.has_key?(p)
          form.submission.write_from_db(p, position)
        end
      end

      def init_condition_attrs_to_clean(conditions = self.conditions)
        return unless conditions.any?
        conditions.each do |condition|
          form.condition_attrs_to_clean[condition] ||= {}
          form.condition_attrs_to_clean[condition][self.path] = true
        end
      end

      def input_name
        @input_name ||= "#{input_prefix}[#{attribute_name}]"
      end

      def form_group_id
        @form_group_id ||= input_name&.gsub(/\[|\./, '-')&.gsub(']', '')&.gsub('@', '__')
      end

      def input_id
        return @input_id if @input_id
        @input_id = "input-#{form_group_id}"
        if form
          if form.input_ids.include?(@input_id)
            i = 0
            begin
              i += 1
            end while form.input_ids.include?("#{@input_id}-#{i}")
            @input_id = "#{@input_id}-#{i}"
          end
          form.input_ids << @input_id
        end
        return @input_id
      end

      def input_css_id
        @input_css_id ||= "##{input_id}"
      end

      def value_id(idx)
        "#{input_id}-value-#{idx}"
      end

      def input_errors
        if record.try(:errors)
          attributes_for_errors.each do |attr|
            record.errors[attr.to_s].try(:each) do |e|
              DIV class: 'invalid-feedback' do
                I18n.error(e, record, attr)
              end
            end
          end
        end
      end

      def input_errors_for_popover
        return unless record.try(:errors)

        result = nil
        attributes_for_errors.each do |attr|
          result ||= ''
          record.errors[attr.to_s].try(:each) do |e|
            result += %Q[<div class="text-danger">#{I18n.error(e, record, attr)}</div>]
          end
        end

        if disconnected?
          result = %Q[<div class="text-danger">#{I18n.t('crm.forms.status_code.401')}</div>]
        end

        return result
      end

      def disconnected?
        record.unauthorized? || (record.status_code == 422 && record.errors[:error] == 'invalid_authenticity_token')
      end

      def attributes_for_errors
        [attribute_name] + Array(errors_from)
      end

      def invalid_css_class
        record_is_invalid? ? ' is-invalid' : ''
      end

      def record_is_invalid?
        record && (attributes_for_errors.map(&:to_s) & (record.errors.keys)).any?
      end

      def record_is_invalid_changed?
        r = (@previous_record_is_invalid != record_is_invalid?)
        @previous_record_is_invalid = record_is_invalid?
        return r
      end

      def disabled_by_autocomplete
        return false unless form&.submission
        return false unless form.submission.disabled.any?

        return false if requirement == 'mandatory' && form.submission.was(path).blank? # exception

        return false if form.submission.disabled[prefix_path] && editor == 'autocomplete' # exception

        return !!form.submission.descendant_of_disabled?(prefix_path)
      end

      def change_value(value)
        return unless form && !form.reseting?
        old_value = form.submission.read(path)
        new_value = convert_value(value)
        if new_value != old_value
          form.enable
          form.submission.write_from_user(path, new_value)
          change_data(value)
          mutate
          change!(value, form, self)
          form.change
        end
      end

      def change_values(values, data)
        return unless form && !form.reseting?

        to_change = []
        values.each do |value|
          next unless form.value_can_be_changed?(value[:path])
          old_value = form.submission.read(value[:path])
          new_value = convert_value(value[:value])
          if new_value != old_value
            to_change << value
            form.enable
          end

          form.submission.send(:"write_from_#{value[:from] || 'user'}", value[:path], new_value)
        end

        data.each do |path, datum|
          p = path.dup
          data_assoc = p.pop
          data_input_prefix = compute_input_prefix(p)
          h = form.submission.data[data_input_prefix] ||= {} # TODO find a way to clean data
          h.merge!(data_assoc => datum)
        end

        mutate
        to_change.each do |value|
          next unless value[:path] == path  # TODO: Call change! for each element ?
          change!(value[:value], form, self)
        end
        form.mutate
        form.change
      end

      def change_data(value, record = self.record) # can be redefined
      end

      def convert_value(value)
        return if nullify? && value == ''
        return value
      end

      def nullify?
        !!other_params[:nullify]
      end

      def forced_default_value?
        mode == 'input' && force_default_value
      end

      def attribute_names
        [attribute_name]
      end

      def possible_values
        other_params[:possible_values] || []
      end

      def label_col_size
        other_params[:label_col_size] || "col-#{breakpoint}-#{label_col_count}"
      end

      def input_col_size
        return 'col'  unless show_label
        other_params[:input_col_size] || "col-#{breakpoint}-#{input_col_count}"
      end

      def label_col_count
        3
      end

      def input_col_count
        9
      end

      def breakpoint
        'md'
      end

      def input_class
        other_params[:input_class]
      end

      def photo_tag(photo, fallback_icon, options = {})
        signed_id = photo&.signed_id
        @photo_errors ||= {}
        if signed_id && !@photo_errors[signed_id]
          IMG(options.merge({
            src: "#{::HyperResource::Base.api_prefix}/files/representations/#{signed_id}/photo-button/photo.png",
            onError: Proc.new{ @photo_errors[signed_id] = true; mutate },
          }))
        else
          SPAN(options) do
            I(class: "fas fa-#{fallback_icon} fa-inverse"){}
          end
        end
      end

      def stub
        DIV(ref: _ref) {}
      end

      def _ref # TODO find a better way to forward ref
        return @ref_proc if @ref_proc_is_set
        r = `#{@__hyperstack_component_native}.props._ref`
        @ref_proc = Proc.new{|a|`#{r}.current = #{a}` } if r
        @ref_proc_is_set = true
        return @ref_proc
      end

      def clear_cached_props(next_props) # Optimize props reset
        if attribute_name != next_props['attribute_name']
          @cached_props = nil
        end
      end

    end

    def self.klass_from_method_name(klass, method_name)
      if klass.attributes[method_name]
        "#{self.name}::Attribute::#{klass.attributes[method_name]['type'].classify}".safe_constantize
      elsif klass.reflect_on_association(method_name)
        "#{self.name}::Association::#{klass.reflect_on_association(method_name).class.name.demodulize.gsub(/Reflection\z/, '')}".safe_constantize
     elsif klass.reflect_on_attachment(method_name)
        "#{self.name}::Attachment::#{klass.reflect_on_attachment(method_name).macro.gsub('_attached', '').classify}".safe_constantize
      end
    end

  end
end
