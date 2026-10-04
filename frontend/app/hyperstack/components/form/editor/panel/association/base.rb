class Form
  class Editor
    module Panel
      module Association
        class Base < Panel::Base
          render { content }

          def parameters
            accordion_style = {width: 'calc(100% + 30px)', position: 'relative', left: '-15px'}
            label_parameter
            target_klasses_parameter
            requirement_parameter
            help_parameter
            watermark_parameter
            editor_parameter
            if ['radio', 'radio_inline', 'checkbox', 'checkbox_inline'].include?(record.editor)
              value_position_parameter
              show_value_parameter
              values_limit_parameter
            end
            mode_parameter
            create_record_when_not_changed_parameter
            min_max_parameters
            if ['radio', 'radio_inline', 'checkbox', 'checkbox_inline', 'select2', 'tom_select', nil].include?(record.editor)
              ::Form::Element::Layout::Accordion(
                title: I18n.t('activerecord.values.dynamic/form/element/base.section.sorting'),
                style: accordion_style
              ) do
                sorting_parameter
              end
            end
            ::Form::Element::Layout::Accordion(
              title: I18n.t('activerecord.values.dynamic/form/element/base.section.filter'),
              style: accordion_style
            ) do
              filters_parameter
            end
            if ['radio', 'radio_inline', 'checkbox', 'checkbox_inline'].include?(record.editor)
              ::Form::Element::Layout::Accordion(
                title: I18n.t('activerecord.values.dynamic/form/element/base.section.possible_value'),
                style: accordion_style
              ) do
                possible_values_parameter
              end
            end
            ::Form::Element::Layout::Accordion(
              title: I18n.t('activerecord.values.dynamic/form/element/base.section.default_value'),
              style: accordion_style
            ) do
              default_value_parameter
            end
            css_classes_parameter
            column_layout_parameters
            parent_settings_parameters
            condition_parameter
            errors_from_parameter
            disabled_parameter
          end

          def sorting_parameter
            Form::Element::Attribute::Enum(
              label: I18n.t("activerecord.values.dynamic/form/element/base.sorting_attribute.title"),
              attribute_name: 'sorting_attribute',
              possible_values: possible_attrs,
            )
            Form::Element::Attribute::Enum(
              label: I18n.t("activerecord.values.dynamic/form/element/base.sorting_type.title"),
              attribute_name: 'sorting_type',
              possible_values: possible_sorting_types,
            )
          end

          def possible_attrs
            return [] unless target_klass
            result = []
            target_klass.attribute_names.each do |attr|
              next if attr.end_with?('_ids') || attr.end_with?('_id')
              result << {
                label: target_klass.human_attribute_name(attr),
                value: attr,
              }
            end
            result
          end

          def possible_sorting_types
            [
              'asc',
              'desc'
            ].map do |k|
              {
                value: k,
                label: I18n.t("activerecord.values.dynamic/form/element/base.sorting_type.#{k}")
              }
            end
          end

          def default_value_parameter
            # redefined
          end

          def target_klass
            return record.klass.reflect_on_association(record.attribute_name)&.klass
          end

          def target_klass_url
            if target_klass
              target_klass.collection_path
            elsif record.klass && record.klass.parent.respond_to?(:search_path)
              record.klass.parent.search_path(klass_names: record.target_klass_names)
            end
          end

          def target_klasses_parameter
            klass_ = record.klass_name.safe_constantize
            association_name_ = record.attribute_name
            target_klass_ = klass_.reflect_on_association(association_name_)&.klass
            return if target_klass_
            ::Form::Element::Attribute::MultipleEnum(
              attribute_name: 'target_klass_names',
              possible_values: possible_target_klass_names,
              editor: 'select',
              special_all_value: true,
              default_value: ::Form::Element::Attribute::MultipleEnum::ALL,
            )
          end

          def possible_target_klass_names
            schema_module = record.klass.parent
            klass_names = schema_module.constants.select do |k|
              schema_module.const_get(k) < schema_module.const_get(:DynamicRecord)
            end.map{|k| schema_module.const_get(k) }
            result = klass_names.map do|k|
              {
                value: k.name,
                label: k.model_name.human,
              }
            end
            return result
          end

          def mode_parameter
            ::Form::Element::Attribute::Enum(
              attribute_name: 'mode',
              placeholder: I18n.t('activerecord.values.dynamic/form/element/base.mode.default'),
              possible_values: possible_modes,
              nullify: true,
            ).on(:change) do |value|
              record.attributes['mode'] = value
              after(0.1) do
                mutate
              end
            end
          end

          def possible_modes
            # TODO return modes according to form.mode
            [
              'input',
              'nested_form',
            ].map do |k|
              {
                value: k,
                label: I18n.t("activerecord.values.dynamic/form/element/base.mode.#{k}")
              }
            end
          end

          def create_record_when_not_changed_parameter
            ::Form::Element::Layout::Condition(mode: 'nested_form') do
              ::Form::Element::Attribute::Boolean(
                attribute_name: 'create_record_when_not_changed',
              )
            end
          end

          def min_max_parameters # redefined
          end

          def filters_parameter
            return unless target_klass && record.mode != 'nested_form'
            Filters(key: "filters-#{record.id}", attribute_name: 'autocomplete_filters', klass: target_klass, root_klass: record.root_klass, get_variable: get_variable)
          end

          def get_variable
            @get_variable ||= Proc.new do |result|
              other_params[:enableInspectMode].call(
                Proc.new do |element|
                  attrs = Hash.new(element)
                  r = (attrs[:method_names].to_a + [attrs[:attribute_name]]).join('.')
                  result.call(r)
                end.to_n
              )
            end
          end

          def condition_parameter
            return unless target_klass && record.mode == 'nested_form'
            ConditionFormula(key: "condition-#{record.id}", attribute_name: 'condition_formula', klass: target_klass)
          end

          def possible_values_parameter
            attribute_name = record.attribute_name
            target_klass = record.klass.reflect_on_association(attribute_name).klass
            Form::Element::Association::HasMany(attribute_name: 'possible_values', mode: 'nested_form') do
              Form::Element::Attribute::String(attribute_name: 'text')
              Form::Element::Association::BelongsTo(attribute_name: 'value_record', target_klass: target_klass, polymorphic: true)
            end
            Form::Element::Control::AddButton(attribute_name: 'possible_values', in_editor: true)
          end

          def values_limit_parameter
            Form::Element::Attribute::Integer(attribute_name: 'values_limit')
          end
        end
      end
    end
  end
end
