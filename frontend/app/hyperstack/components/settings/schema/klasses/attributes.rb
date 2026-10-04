# backtick_javascript: true

class Settings

  class Schema

    class Attributes < Klasses::Base

      render { content }

      def klass
        ::Dynamic::Schema::Attribute::Base
      end

      def new_record
        klass.new({
          schema_id: match.params['schema_id'],
          klass_id: match.params['klass_id'],
          baseklass_id: schema_klass.baseklass_id,
          type: 'String',
        })
      end

      def self.includes_for_show
        {
          include: {
            translations: 1,
            values: {
              values: { only: ['id', 'name'] }
            },
            normalizations: 1,
          }
        }
      end

      def self.children_items(schema)
        []
      end

      class EditPanel < ::Settings::Schema::EditPanel

        render { content }

        DEFAULT_CURRENCY = 'EUR'.freeze

        SCALED_FORMATS = ['thousands', 'millions', 'billions', 'ppm'].freeze

        def form
          Form(record: record) do
            Form::Element::Attribute::TranslatableString(
              attribute_name: 'human_name',
              errors_from: 'name',
              help: record.new_record? ? '' : I18n.t('activerecord.defaults.attributes.variable_name_text', variable_name: record.name),
              auto_focus: true,
            )
            Form::Element::Attribute::Enum(
              attribute_name: 'type',
              disabled: record.persisted?,
              errors_from: ['column'],
              help: type_help,
            ) do
              ::Dynamic::Schema::Attribute::Base.subclasses.map do |klass|
                OPTION(value: klass.name.demodulize) do
                  klass.try(:model_name).try(:human) || klass.name
                end
              end
            end.on(:change) do
              mutate
            end
            if record.new_record?
              Form::Element::Attribute::Boolean(
                attribute_name: 'index',
                default_value: false,
              )
            end
            if record.persisted? && record.class.try(:formats)&.length.to_i > 1 && !date_type?
              Form::Element::Attribute::Enum(
                attribute_name: 'format'
              ).on(:change) do
                mutate
              end
              Form::Element::Layout::Condition(format: ['unit'] + SCALED_FORMATS) do
                Form::Element::Attribute::Hash(attribute_name: 'format_options', mode: 'nested_form') do
                  Form::Element::Attribute::String(
                    attribute_name: 'symbol',
                    label: I18n.t('activerecord.attributes.dynamic/schema/attribute/float.format_options.symbol.label'),
                    placeholder: I18n.t('activerecord.attributes.dynamic/schema/attribute/float.format_options.symbol.placeholder'),
                  ).on(:change) do
                    mutate
                  end
                end
              end
              Form::Element::Layout::Condition(format: 'currency') do
                Form::Element::Attribute::Hash(attribute_name: 'format_options', mode: 'nested_form') do
                  Form::Element::Attribute::Enum(
                    attribute_name: 'currency',
                    label: I18n.t('activerecord.attributes.dynamic/schema/attribute/float.format_options.currency.label'),
                    possible_values: currency_possible_values,
                    default_value: DEFAULT_CURRENCY,
                    accept_empty_value: false,
                    nullify: true,
                  ).on(:change) do
                    mutate
                  end
                end
              end
              Form::Element::Layout::Condition(type: 'Float') do
                Form::Element::Layout::Condition(format: ['locale', 'x100_percentage', 'currency', 'unit'] + SCALED_FORMATS) do
                  Form::Element::Attribute::Hash(attribute_name: 'format_options', mode: 'nested_form') do
                    Form::Element::Attribute::Enum(
                      attribute_name: 'precision',
                      label: I18n.t('activerecord.attributes.dynamic/schema/attribute/float.format_options.precision.label'),
                      possible_values: precision_possible_values,
                      nullify: true,
                    ).on(:change) do
                      mutate
                    end
                  end
                end
              end
              Form::Element::Layout::Condition(type: 'Integer') do
                Form::Element::Layout::Condition(format: ['locale', 'percentage', 'currency', 'unit']) do
                  Form::Element::Attribute::Hash(attribute_name: 'format_options', mode: 'nested_form') do
                    Form::Element::Attribute::Integer(
                      attribute_name: 'precision',
                      editor: 'hidden',
                      default_value: 0,
                    )
                  end
                end
              end
              render_format_preview if selected_format.present?
            end
            if record.persisted?
              Form::Element::Layout::Condition(type: ['Date', 'DateTime']) do
                Form::Element::Attribute::Hash(attribute_name: 'format_options', mode: 'nested_form') do
                  Form::Element::Attribute::Enum(
                    attribute_name: 'precision',
                    label: I18n.t('activerecord.attributes.dynamic/schema/attribute/date.format_options.precision.label'),
                    help: I18n.t('activerecord.attributes.dynamic/schema/attribute/date.format_options.precision.help'),
                    help_position: 'icon',
                    possible_values: date_precision_possible_values,
                    nullify: true,
                  ).on(:change) do
                    mutate
                  end
                end
              end
              render_format_preview if date_type?
            end
            if record.persisted? && record.class.editors.length > 1
              Form::Element::Attribute::Enum(
                attribute_name: 'editor'
              ).on(:change) do
                mutate
              end
            end
            if record.attributes[:type] == 'String'
              Form::Element::Attribute::MultipleEnum( # TODO make it possible to use a primary protocol (first in list)
                attribute_name: 'protocols',
                editor: 'select2',
              )
            end
            if ['String', 'Text', 'TranslatableString', 'TranslatableText'].include?(record.attributes[:type])
              Normalizations(
                attribute_name: 'normalizations',
                editor: 'select2',
                polymorphic: true,
                errors_from: ['normalizations[0].attr'],
              )
            end
            if schema.has_feature_enabled?('Dynamic::Formula::Feature')
              Formula(
                attribute_name: 'formula',
                schema: schema,
                height: '300px',
              )
            end
            default_value_input
            comment
            Form::Element::Layout::Condition(type: 'String') do
              Form::Element::Attribute::Boolean(
                attribute_name: 'incremental',
                help: I18n.t('sequence.help'),
                help_position: 'icon',
              )
            end
            if record.attributes[:type] == "Enum"
              DIV(class: "row") do
                LABEL(class: "col-md-3 control-label") { I18n.t("activerecord.attributes.dynamic/schema/attribute/base.enum_type_value_text") }
                DIV(class: "col-md-9") do
                  TABLE(class: "table table-bordered") do
                    THEAD do
                      TR do
                        TH { I18n.t("activerecord.defaults.attributes.name") }
                        TH { I18n.t("activerecord.attributes.dynamic/schema/attribute/base.technical_name") }
                      end
                    end
                    TBODY do
                      record.values&.each do |value|
                        TR do
                          TD { value.human_name }
                          TD { value.name }
                        end
                      end
                    end
                  end
                end
              end
            end
            children_list
          end.on(:success) do
            App.history.push(record_location)
          end
        end

        # stored as typed by the user, cast to the attribute type by dynamic_record when the schema is loaded
        def default_value_input
          return if record.formula.present?
          return if record.attributes[:incremental]

          case record.attributes[:type]
          when 'Enum'
            Form::Element::Attribute::Enum(attribute_name: 'default_value') do
              OPTION(value: '')
              record.values&.each do |value|
                OPTION(value: value.name) { value.human_name }
              end
            end
          when 'Boolean'
            Form::Element::Attribute::Enum(attribute_name: 'default_value') do
              OPTION(value: '')
              OPTION(value: 'true') { I18n.t('shared._yes') }
              OPTION(value: 'false') { I18n.t('shared._no') }
            end
          when 'Date'
            Form::Element::Attribute::Date(attribute_name: 'default_value', precision: record.format_options.try(:[], 'precision'))
          when 'DateTime'
            Form::Element::Attribute::DateTime(attribute_name: 'default_value', precision: record.format_options.try(:[], 'precision'))
          when 'TimeOfDay'
            Form::Element::Attribute::TimeOfDay(attribute_name: 'default_value')
          else
            Form::Element::Attribute::String(attribute_name: 'default_value')
          end
        end

        def type_help
          return unless record.new_record?
          "#{I18n.t("settings.klasses.attributes.available_count", count: available_count)} #{I18n.t("settings.klasses.attributes.available_index_count", count: available_indexed_count)}"
        end

        def currency_possible_values
          @currency_possible_values ||= begin
            locale = I18n.locale.to_s
            codes_and_labels = `(function() {
              var codes = Intl.supportedValuesOf('currency');
              var names = new Intl.DisplayNames([#{locale}], { type: 'currency' });
              return codes.map(function(c) { return [c, c + ' — ' + names.of(c)]; });
            })()`
            codes_and_labels.map { |code, label| { value: code, label: label } }
          end
        end

        def precision_possible_values
          @precision_possible_values ||= (0..5).map { |p| { value: p, label: p.to_s } }
        end

        DATE_PRECISIONS = ['year', 'month', 'day'].freeze
        DATE_TIME_PRECISIONS = (DATE_PRECISIONS + ['hour', 'minute', 'second']).freeze

        def date_precision_possible_values
          precisions = selected_type == 'Date' ? DATE_PRECISIONS : DATE_TIME_PRECISIONS
          return precisions.map do |p|
            {
              value: p,
              label: I18n.t("activerecord.attributes.dynamic/schema/attribute/date.format_options.precision.#{p}"),
            }
          end
        end

        def date_type?
          ['Date', 'DateTime'].include?(selected_type)
        end

        def render_format_preview
          fmt = selected_format
          fmt_options = current_format_options.dup
          fmt_options[:currency] ||= DEFAULT_CURRENCY if fmt.to_s == 'currency'
          fmt_options = UneekFormatting::Dynamic::AttributeFormatter.default_options_for(selected_type, fmt).merge(fmt_options)
          method, options = UneekFormatting::Dynamic::AttributeFormatter.format_method_for_key(fmt, fmt_options, selected_type) || []
          return unless method
          sample = format_preview_sample(selected_format)
          rendered = UneekFormatting::Dynamic::AttributeFormatter.send(method, sample, options)
          DIV(class: "form-group row") do
            LABEL(class: "col-md-3 control-label") do
              I18n.t('settings.klasses.attributes.format_preview')
            end
            DIV(class: "col-md-9") do
              SPAN(class: "form-control-plaintext text-muted") do
                "#{format_preview_source(sample)} → #{rendered}"
              end
            end
          end
        end

        def format_preview_source(sample)
          return sample if date_type?
          return UneekFormatting::NumberHelper.number_to_rounded(sample, precision: nil)
        end

        def format_preview_sample(fmt)
          return date_preview_sample if date_type?
          integer = record.attributes[:type] == 'Integer'
          sample =
            case fmt.to_s
            when 'x100_percentage'                     then 0.1523
            when 'percentage'                          then 15.23
            when 'ppm'                                 then integer ? 5.0 : 0.0005
            when 'thousands', 'millions', 'billions'   then 1234567.0
            else                                            1234.567
            end
          integer ? sample.to_i : sample
        end

        def date_preview_sample
          length = selected_type == 'Date' ? 10 : 19
          return `new Date(Date.now() + 3 * 86400000).toISOString().slice(0, length)`
        end

        def current_format_options
          fs = Form.current&.submission
          if fs
            prefix = ['attribute', 'format_options']
            result = fs.values.each_with_object({}) do |(path, value), hash|
              next unless path.is_a?(Array) && path.length == prefix.length + 1 && fs.array_start_with?(path, prefix)
              hash[path.last] = value
            end
            return result if result.any?
          end
          opts = record.format_options
          opts.is_a?(::Hash) ? opts : {}
        end

        def available_count
          total_count - used_count
        end

        def total_count
          Dynamic::Schema::Klass::TABLE_PROFILE.dig(baseklass&.table_profile, type_for_count, :count) || 0
        end

        def used_count
          shared_attrs.length
        end

        def available_indexed_count
          total_index_count - used_index_count
        end

        def total_index_count
          Dynamic::Schema::Klass::TABLE_PROFILE.dig(baseklass&.table_profile, type_for_count, :indexed) || 0
        end

        def used_index_count
          shared_attrs.select{|a| a.index}.length
        end

        def attrs
          # TODO it should be all attributes of descendent of baseklass
          @attrs ||= []
          r =  Dynamic::Schema::Attribute::Base.includes(only: [:d, :type]).where(schema_id: record.schema_id, klass_id: record.klass_id)
          observe r
          r.all do |records|
            @attrs = records
          end
          @attrs
        end

        def shared_attrs
          attrs.select{|a| SHARING_SAME_PRIMITIVE_TYPES[selected_type].include?(a.type) }
        end

        def selected_type
          Form.current&.submission&.read(['attribute', 'type']) || record.type
        end

        def selected_format
          Form.current&.submission&.read(['attribute', 'format']) || record.format
        end

        def type_for_count
          if primitive_type&.start_with?('Translatable')
            # translatable have same count as non-translatable
            return primitive_type&.gsub('Translatable', '')
          else
            return primitive_type
          end
        end

        def primitive_type
          PRIMITIVE_TYPE[selected_type]
        end

        PRIMITIVE_TYPE = {
          'Boolean' => 'Boolean',
          'Date' => 'DateTime',
          'DateTime' => 'DateTime',
          'Enum' => 'Uuid',
          'Float' => 'Float',
          'String' => 'String',
          'Text' => 'Text',
          'TimeOfDay' => 'String',
          'Integer' => 'Integer',
          'Uuid' => 'Uuid',
          'TranslatableString' => 'TranslatableString',
          'TranslatableText' => 'TranslatableText',
        }

        SHARING_SAME_PRIMITIVE_TYPES = {
          'Boolean' => [ 'Boolean' ],
          'Date' => [ 'DateTime', 'Date' ],
          'DateTime' => [ 'DateTime', 'Date' ],
          'Enum' => [ 'Enum', 'Uuid' ],
          'Float' => [ 'Float' ],
          'String' => [ 'String', 'TimeOfDay' ],
          'Text' => [ 'Text' ],
          'TimeOfDay' => [ 'String', 'TimeOfDay' ],
          'Integer' => [ 'Integer' ],
          'Uuid' => [ 'Enum', 'Uuid' ],
          'TranslatableString' => [ 'TranslatableString' ],
          'TranslatableText' => [ 'TranslatableText' ],
        }

        def baseklass
          schema.klasses.detect{|k| k.id == record.baseklass_id}
        end

        def children_items
          children_klasses = []
          if record.is_a?(::Dynamic::Schema::Attribute::Enum)
            children_klasses << ::Dynamic::Schema::Attribute::Enum::Value
          end
          children_klasses << ::Dynamic::Schema::Validation::Base
          if record.is_a?(::Dynamic::Schema::Attribute::String)
            children_klasses << ::Dynamic::Schema::Sequence
          end
          items = children_klasses.map do |a|
            {
              id: self.class.parent.resources_name(a),
              icon: a.icon,
              title: a.model_name.human(count: 2),
            }
          end
          if schema&.has_feature_enabled?('Dynamic::Datatable::Style::Feature')
            items << {
              id: 'styles',
              icon: 'fa fa-palette',
              title: I18n.t('settings.attributes.styles.title'),
            }
          end

          items
        end

        private

        def footer
          form_footer
        end

      end

      class Normalizations < Form::Element::Association::HasMany

        def self.normalization_subclasses
          list_items = ::Dynamic::Schema::Normalization::Base.subclasses.map do |klass|
            id_item = HyperResource::Base.generate_uuid
            {
              id: id_item,
              value: id_item,
              record: {
                id: id_item,
                type: klass.name ,
                options: nil,
              },
              text: (klass.try(:model_name).try(:human) || klass.name)+ "+",
            }
          end
          id_item = HyperResource::Base.generate_uuid
          list_items << {
            id: id_item,
            value: id_item,
            record: {
              id: id_item,
              type: 'Dynamic::Schema::Normalization::CapitalizeAllWords',
              options: { with_dash: true },
            },
            text: 'WITH DASH'
          }
          list_items
        end

        def value_from_tom_select_data
          current_items = `#{select_element.to_n}[0].tomselect.items`
          @tom_select_record_cache ||= {}
          current_items.each do |id|
            d = items_cache[id]
            r = `#{d}.record`
            next unless r
            attrs = ::Hash.new(r)
            @tom_select_record_cache[id] ||= polymorphic_new(attrs)
          end
          ci = current_items.map{|id| @tom_select_record_cache[id] || record_from_submission_data(id) }
          ci.each_with_index do |item, i|
            if item == nil
              id = current_items[i]
              type = `#{select_element.to_n}[0].tomselect.options[#{id}].record.type`
              unless `#{select_element.to_n}[0].tomselect.options[#{id}].record.options == null`
                name_option = `Object.keys(#{select_element.to_n}[0].tomselect.options[#{id}].record.options)[0]`
                value_option = `#{select_element.to_n}[0].tomselect.options[#{id}].record.options[#{name_option}]`.to_n
                options = {}
                options[name_option] = value_option
                ci[i] = {
                  id: id,
                  type: type,
                  options: options,
                }
              else
                ci[i] = {
                  id: id,
                  type: type,
                }
              end
            end
          end
          return ci
        end

        def change_value(value)
          return super if attribute_name.end_with?('_ids') || attribute_name.end_with?('_id')
          return unless form && !form.reseting?

          old_value = form.submission.read_association(path)
          old_value = [] if old_value == nil
          old_value_count = 0
          old_value.each do |item|
            unless item[:_destroy] == '1'
              old_value_count += 1
            end
          end
          new_value = convert_value(value)
          deleted_value = nil

          if new_value != old_value
            if new_value.count > old_value_count
              old_value.each do |old_item|
                result = new_value.find{|new_item| new_item[:id] == old_item[:id]}
                if result.nil?
                  new_value << old_item
                end
              end
            else
              deleted_value = old_value - new_value
              deleted_value.each do |delete_item|
                if delete_item[:_destroy] == '1'
                  new_value << delete_item
                  deleted_value.delete(delete_item)
                end
              end
              deleted_value = deleted_value.first
              deleted_value[:_destroy] = '1'
              new_value << deleted_value
            end
          end
          form.enable
          form.submission.write_association(path, new_value)
          form.submission.write_association_values(path, new_value)
          change_data(value)
          mutate
          change!(value, form, self)
          form.change
        end

        def convert_value(value)
          if attribute_name.end_with?('_ids')
            convert_value_to_id(value)
          else
            return value unless value.is_a?(Array) || value.is_a?(HyperResource::Relation)
            return value.compact.map do |e|
              if polymorphic?
                if e.class == Hash
                  {
                    'id' => e["id"],
                    'type' => e["type"],
                    'options' => e["options"],
                  }
                else
                  {
                    'id' => e.id,
                    'type' => e.type,
                    'options' => e.options,
                  }
                end
              else
                { 'id' => e.id }
              end
            end
          end
        end

        def self.tom_select_options(target_klass, target_klass_url, css_class = nil, autocomplete_variables_proc = nil, cache_items_proc = nil)
          r = {
            valueField: 'id',
            allowEmptyOption: true,
            plugins: ['remove_button'],
            shouldLoad: Proc.new { |query| true },
            onFocus: Proc.new do
              `this.load()`
            end,
          }
          r[:load] = Proc.new  do |query, callback|
            items = self.normalization_subclasses.to_n
            component = `this.hyperstack_component`
            list_type_selected = []
            component.selected_data.each do |data|
              list_type_selected << {type: data.type, options: data.options}
            end
            new_items = []
            items.each do |item|
              option = nil
              if `item.record.options != null`
                name_option = `Object.keys(item.record.options)[0]`
                value_option = `item.record.options[#{name_option}]`.to_n
                option = {}
                option[name_option] = value_option
              end
              unless list_type_selected.include?({type: `item.record.type`, options: option})
                new_items << item
              end
            end

            `callback(#{new_items})`

          end
          r[:render] = super[:render]
          r[:render][:option] = Proc.new do |item, escape|
            fallback_icon = target_klass.try(:icon) || item_icon(item)
            if `item.record`
              t = `item.record.type`.underscore
              o = `item.record.options`
              unless `#{o} == null`
                name_option = `Object.keys(o)[0]`
                `item.text = #{I18n.t("activerecord.models.#{t}.one")} +
                  " ( " +
                  #{I18n.t("activerecord.attributes.dynamic/schema/normalization/base.options.#{name_option}")}
                  + " )" `
              else
                `item.text = #{I18n.t("activerecord.models.#{t}.one")}`
              end
            end
            next '<div>' + tom_select_item_template(`item.text`, `item.photo_id`, fallback_icon) + '</div>'
          end

          r
        end

        def selected_data
          return [] unless form
          return form.submission.read_ids(path).map do |id|
            d = form.submission.data.dig(input_prefix, attribute_name)&.detect{|a| a.id == id }
            d
          end
        end

        def record_name(r)
          if r.nil?
            return ""
          end
          unless r.options == nil
            r.try(r&.class.try(:name_attribute) || 'name') + " ( " + I18n.t("activerecord.attributes.dynamic/schema/normalization/base.options.#{r.options.keys[0]}") +" )"
          else
            r.try(r&.class.try(:name_attribute) || 'name')
          end
        end
      end

      class CollectionPage < ::Settings::Schema::CollectionPage
        include ::Settings::Schema::Klasses::Base::RecomputeFormulaMenuItem
        include ::Settings::Schema::Klasses::Base::ItemIconAssigner

        def action_menu_items
          item_recompute_formula
          item_delete
        end

        def model_to_item(model)
          item = super(model)
          return item unless item
          attach_icons_to_item(model, item)
          klass = schema.klasses.detect { |k| k.id == model.klass_id }
          if klass&.name_attribute_id == model.id
            item[:icons] << { icon: 'fa fa-address-card', tooltip: I18n.t('activerecord.attributes.dynamic/schema/klass.name_attribute') }
          end
          item
        end
      end
    end
  end
end
