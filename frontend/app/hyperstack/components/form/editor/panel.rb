class Form
  class Editor
    module Panel
      class Base < HyperComponent

        param :element, default: {}
        param :delete_promise, default: nil

        collect_other_params_as :other_params

        render { content }

        def content
          DIV do
            title
            Form(
              record: record,
              class: 'container-fluid',
            ) do
              parameters
            end.on(:change) do |form|
              attrs = form.submission.params.values.first
              attrs_copy = attrs.dup
              if attrs_copy.has_key?('parent_attributes')
                attrs_copy['parent'] = Array(attrs_copy.delete('parent_attributes')).first
              end
              other_params[:updateSelectedElementAttributes].call(attrs_copy.to_n)
              if record.parent && attrs_copy['parent']
                css_classes = attrs_copy['parent']['css_classes']
                css_classes.delete('id')
                other_params[:updateElementById].call(
                  record.parent.id,
                  { css_classes: css_classes }
                )
              end
            end
          end
        end

        def rescued_error_message
          DIV(class: 'border-bottom mb-3 d-flex align-items-start') do
            DIV(class: 'p-2'){}
            spacer
            delete_btn
          end
          super
        end

        def title
          DIV(class: 'border-bottom mb-3 d-flex align-items-start') do
            DIV(class: 'p-2') do
              title_path
            end
            add_same_as_id_attr_btn
            spacer
            delete_btn
          end
          same_as_element_path
        end

        def title_path
          path = human_path(record.root_klass, record.method_names.to_a + [record.attribute_name])
          path.each_with_index do |p, i|
            SPAN { p }
            chevron if i != path.length - 1
          end
        end

        def same_as_element_path
          return unless element[:same_as_id]

          hash_element = other_params[:getElementById].call(element[:same_as_id]).to_h
          readable_paths = human_path(record.root_klass, hash_element[:method_names].to_a + [hash_element[:attribute_name]])

          DIV(class: 'border-bottom mb-3 mt-n3 d-flex align-items-start') do
            DIV(class: 'p-2') do
              readable_paths.each_with_index do |p, i|
                SPAN { p }
                chevron if i != readable_paths.length - 1
              end
            end
            spacer
            remove_same_as_id_attr_btn
          end
        end

        def parameters
        end

        def accordion_style
          return {width: 'calc(100% + 30px)', position: 'relative', left: '-15px'} # TODO replace with bootstrap 5 mx-n2
        end

        def column_layout_parameters
          ::Form::Element::Layout::Accordion(
            title: I18n.t('activerecord.values.dynamic/form/element/base.section.column_layout.title'),
            style: accordion_style,
            is_last: true,
          ) do
            compact_parameter

            ::Form::Element::Attribute::Enum(
              attribute_name: 'label_col_size',
              label: I18n.t('activerecord.values.dynamic/form/element/base.section.column_layout.label_width'),
              possible_values: col_size_options,
              default_value: 'col-md-3',
            )

            ::Form::Element::Attribute::Enum(
              attribute_name: 'input_col_size',
              label: I18n.t('activerecord.values.dynamic/form/element/base.section.column_layout.input_width'),
              possible_values: col_size_options,
              default_value: 'col-md-9',
            )

            unless current_total_valid?
              DIV(class: 'alert alert-warning alert-sm mt-2 mb-0') do
                I(class: 'fas fa-exclamation-triangle mr-2')
                SMALL { I18n.t('activerecord.values.dynamic/form/element/base.section.column_layout.warning') }
              end
            end
          end
        end

        def compact_parameter
          ::Form::Element::Attribute::Boolean(
            attribute_name: 'compact',
          ).on(:change) do |value|
            record.attributes['compact'] = value
            after(0.1) do
              mutate
            end
          end
        end

        def current_label_col_count
          extract_col_size('label_col_size', 3)
        end

        def current_input_col_count
          extract_col_size('input_col_size', 9)
        end

        def parent_width_field
          ::Form::Element::Attribute::Hash(
            attribute_name: 'css_classes',
            mode: 'nested_form',
          ) do
            parent_column_size
          end
        end

        def parent_column_size
          ::Form::Element::Attribute::Enum(
            attribute_name: 'width',
            label: I18n.t('activerecord.values.dynamic/form/element/base.section.parent_setting.width'),
            possible_values: (1..12).map do |size|
              {
                value: "col-md-#{size.to_s}",
                label: "#{size}/12 (#{(size * 100.0 / 12).round}%)"
              }
            end
          )
        end

        def delete_btn
          A(href: '#', class: 'btn btn-light') do
            I(class: 'fas fa-trash') {}
          end.on(:click) do |event|
            event.prevent_default
            other_params[:deleteSelectedElement].call
          end
        end

        def add_same_as_id_attr_btn
          return unless element['type'].match?(/Association::HasMany|Association::BelongsTo/)
          A(href: '#', class: 'btn btn-light border-left') do
            I(class: 'fa fa-crosshairs') {}
          end.on(:click) do |event|
            event.prevent_default
            other_params[:enableInspectMode].call(
              Proc.new do |inspected_element|
                attrs = Hash.new(inspected_element)
                if same_as_element_compatible?(attrs)
                  update_same_as_id.call(attrs[:id])
                else
                  Modal.confirm(
                    title: I18n.t('activerecord.values.dynamic/form/element/base.editor.unauthorized_action'),
                    text: I18n.t('activerecord.values.dynamic/form/element/base.editor.association_error'),
                    cancelClass:'d-none',
                    commit: 'Ok'
                  ){}
                end
              end.to_n
            )
          end
        end

        def remove_same_as_id_attr_btn
          A(href: '#', class: 'btn btn-light') do
            I(class: 'fa fa-minus') {}
          end.on(:click) do |event|
            event.prevent_default
            update_same_as_id.call(nil)
          end
        end

        def spacer
          DIV(class: 'flex-grow-1') {}
        end

        def mode
          other_params[:formMode]
        end

        private

        def parent_settings_parameters
          return unless parent_is_column?

          ::Form::Element::Layout::Accordion(
            title: I18n.t('activerecord.values.dynamic/form/element/base.section.parent_setting.title'),
            style: accordion_style
          ) do
            ::Form::Element::Association::BelongsTo(
              attribute_name: 'parent',
              mode: 'nested_form',
              label: '',
            ) do
              parent_width_field
            end
          end
        end

        def extract_col_size(key, default_value)
          class_name = element[key].to_s
          class_name.match(/col-\w+-(\d+)/)&.[](1)&.to_i || default_value
        end

        def current_total_valid?
          current_label_col_count + current_input_col_count <= 12
        end

        def parent_is_column?
          record.parent.is_a?(::Dynamic::Form::Element::Layout::Column)
        end

        def same_as_element_compatible?(attrs)
          return false if element[:id] == attrs[:id]
          element_target_klass = element[:klass_name]&.safe_constantize&.reflect_on_association(element[:attribute_name])&.klass
          same_as_element_target_klass = attrs[:klass_name]&.safe_constantize&.reflect_on_association(attrs[:attribute_name])&.klass
          return element_target_klass == same_as_element_target_klass
        end

        def update_same_as_id
          return Proc.new do |same_as_id|
            element['same_as_id'] = same_as_id
            other_params[:updateSelectedElementAttributes].call(element.to_n)

            after(0.1) do # Why
              mutate
            end
          end
        end

        def record
          @record = nil if @record && (element['id'] != @record.id || element['updated_at'] != @record.updated_at)
          element_ = element.is_a?(Hash) ? element : Hash.new(element.to_n) # workaround HyperComponent#props_ because it is now a native object instead of a hash. Should polymorphic_new work with native objects ?
          @record ||= ::Dynamic::Form::Element::Base.polymorphic_new(element_)
          @record
        end

        def record_klass
          record&.klass_name&.safe_constantize
        end

        def chevron
          I(class: 'fas fa-chevron-right px-2'){}
        end

        def root_klass_human_name
          record.root_klass&.model_name&.human
        end

        def human_attribute_name
          record.klass&.human_attribute_name(record.attribute_name)
        end

        def human_path(klass, path)
          return [] unless klass && path.any?
          result = []
          begin
            result << klass.model_name.human
            path.each do |m|
              result << klass.human_attribute_name(m)
              reflection = klass.reflect_on_association(m)
              klass = reflection&.klass if reflection
            end
          rescue
          end
          return result
        end

        def label_parameter
          ::Form::Element::Attribute::TranslatableString(
            {
              attribute_name: 'label',
              nullify: true,
            }.merge!(
              placeholders do
                record.klass&.human_attribute_name(record.attribute_name)&.capitalize
              end
            )
          )
          ::Form::Element::Attribute::Boolean(attribute_name: 'show_label', default_value: true)
        end

        def css_classes_parameter
          ::Form::Element::Layout::Accordion(
            title: I18n.t('crm.form_editor.css_classes.accordion_title'),
            style: accordion_style
          ) do
            field_size_option
          end
        end

        def field_size_option
          ::Form::Element::Attribute::Hash(
            attribute_name: 'css_classes',
            mode: 'nested_form',
          ) do
            field_size_parameter
            label_size_parameter
          end
        end

        def field_size_parameter
          ::Form::Element::Attribute::Enum(
            attribute_name: 'field_size',
            placeholder: I18n.t('crm.form_editor.css_classes.field_size.values.normal'),
            label: I18n.t('crm.form_editor.css_classes.field_size.label'),
            possible_values: [
              {label: I18n.t('crm.form_editor.css_classes.field_size.values.large'), value: "form-control-lg#{' h-auto' if mode == 'read_only'}"},
              {label: I18n.t('crm.form_editor.css_classes.field_size.values.small'), value: "form-control-sm#{' h-auto' if mode == 'read_only'}"},
            ]
          )
        end

        def label_size_parameter
          ::Form::Element::Attribute::Enum(
            attribute_name: 'label_size',
            placeholder: I18n.t('crm.form_editor.css_classes.label_size.values.normal'),
            label: I18n.t('crm.form_editor.css_classes.label_size.label'),
            possible_values: [
              {label: I18n.t('crm.form_editor.css_classes.label_size.values.large'), value: "col-form-label-lg"},
              {label: I18n.t('crm.form_editor.css_classes.label_size.values.small'), value: "col-form-label-sm"},
            ]
          )
        end

        def placeholders
          result = {}
          I18n.available_locales.each do |l|
            I18n.with_locale(l) do
              result["placeholder_#{l}"] = yield
            end
          end
          return result
        end

        def editor_parameter
          ::Form::Element::Attribute::Enum(
            attribute_name: 'editor',
            placeholder: I18n.t('activerecord.values.dynamic/form/element/base.editor.default'),
            nullify: true,
          ).on(:change) do |value|
            record.attributes['editor'] = value
            after(0.1) do
              mutate
            end
          end
        end

        def requirement_parameter
          ::Form::Element::Attribute::Enum(attribute_name: 'requirement', accept_empty_value: false)
        end

        def value_position_parameter
          ::Form::Element::Attribute::Enum(attribute_name: 'value_position', accept_empty_value: false)
        end

        def possible_values_parameter
          # TODO
        end

        def help_parameter
          ::Form::Element::Attribute::TranslatableString(attribute_name: 'help', nullify: true)
        end

        def watermark_parameter
          ::Form::Element::Attribute::TranslatableString(attribute_name: 'watermark', nullify: true)
        end

        def default_value_parameter
        end

        def default_value_parameter_from_element_klass
          component_klass = "::Form::Element::#{record.type}".safe_constantize
          return unless component_klass
          component_klass.create_element(attribute_name: 'default_value', target_klass: record.klass).render
          ::Form::Element::Attribute::String(attribute_name: 'default_value_formula', target_klass: record.klass)
          ::Form::Element::Attribute::Enum(attribute_name: 'record_type_for_default_value_formula')
          ::Form::Element::Attribute::Boolean(attribute_name: 'force_default_value', default_value: false)
        end

        def errors_from_parameter
          ::Form::Element::Attribute::MultipleEnum(
            attribute_name: 'errors_from',
            possible_values: possible_values_for_errors_from,
            editor: 'select2',
            default_value: nil,
          )
        end

        def col_size_options
          (0..12).map do |size|
            {
              value: "col-md-#{size}",
              label: "#{size}/12 (#{(size * 100.0 / 12).round}%)"
            }
          end
        end

        def possible_values_for_errors_from
          return @possible_values_for_errors_from if @possible_values_for_errors_from
          attrs_or_associations_or_attachments = []
          if record.klass
            record.klass.attribute_names.each do |attr|
              next if ['created_at', 'updated_at', 'deleted_at'].include?(attr) || (attr.end_with?('_id') && record.klass.reflect_on_association(attr.gsub(/\_id$/, '')))
              attrs_or_associations_or_attachments << attr
            end
            record.klass.reflect_on_all_associations.each do |r|
              attrs_or_associations_or_attachments << r.name
            end
            record.klass.reflect_on_all_attachments.each do |r|
              attrs_or_associations_or_attachments << r.name
            end
            result = record.klass.sort_by_human_name(attrs_or_associations_or_attachments).map{|r| {value: r, label: record.klass.human_attribute_name(r)} }
          end
          @possible_values_for_errors_from = result
          return result
        end

        def disabled_parameter
          ::Form::Element::Attribute::Boolean(attribute_name: 'disabled')
        end

        def show_value_parameter
          ::Form::Element::Attribute::Boolean(attribute_name: 'show_value')
        end

      end
    end
  end
end
