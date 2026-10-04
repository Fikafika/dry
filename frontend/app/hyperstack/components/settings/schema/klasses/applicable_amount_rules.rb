class Settings
  class Schema
    class ApplicableAmountRules < Klasses::Base

      render { content }

      def self.feature
        'Dynamic::Transaction::Feature'
      end

      def self.icon
        ::Dynamic::Transaction::ApplicableAmount::Rule.icon
      end

      def self.model_name
        ::Dynamic::Transaction::ApplicableAmount::Rule.model_name
      end

      def self.disabled?(klass, schema)
        transaction_line_klass = schema.features.detect{|f| f.name == self.feature}&.concerns&.detect{|c| c.name == 'Line::Base'}&.klass
        return klass.id != transaction_line_klass&.id
      end

      def klass
        schema.const_reserved_klass('Transaction::ApplicableAmount::Rule', ::Dynamic::Transaction::ApplicableAmount::Rule)
      end

      def condition_klass
        schema.const_reserved_klass('Transaction::ApplicableAmount::Condition', ::Dynamic::Transaction::ApplicableAmount::Condition)
      end

      def new_record
        klass.new({
          human_name: '',
          conditions: [
            condition_klass.new(
              instance_field: '',
              expression_method: '',
              expression_value: '',
              expression_value_type: ''
            )
          ]
        })
      end

      def self.includes_for_all
        { include: {conditions: 1} }
      end

      def scope_for_all
        {}
      end

      def klass_name
        "D::#{match.params['schema_id'].classify}::#{match.params['klass_id'].classify}"
      end

      def edit_panel
        EditPanel(record: current_model, path: "#{index_location}/:id", schema: schema, klass: klass_name.constantize, schema_klass: schema.klasses.detect {|k| k.name == 'TransactionLine'})
      end

      class EditPanel < ::Settings::Schema::EditPanel

        TRANSLATION_KEY_BY_OPERATION = {
          '==' => 'equal',
          '!=' => 'not_equal',
          '>' => 'greater',
          '<' => 'lesser',
          '>=' => 'greater_equal',
          '<=' => 'lesser_equal',
          'start_with?' => 'starts_with',
          'end_with?' => 'ends_with',
          'include?' => 'contains',
          'exclude?' => 'not_contains'
        }.freeze

        param :klass, default: nil
        param :schema_klass, default: nil

        before_render :init

        before_mount do
          @amount_klass = record.class.reflect_on_association('amount').klass
        end

        render { content }

        def header
          ::Stackable::Toolbar() do
            ::Stackable::PageHeader(title: record.new_record? ? I18n.t('shared.new') : record.name, back: back_location)
          end
        end

        def form
          Form(record: record) do
            Form::Element::Attribute::TranslatableString(
              attribute_name: 'human_name',
              auto_focus: true,
            )
            Form::Element::Attribute::Enum(
              attribute_name: 'applicability',
            )
            Form::Element::Attribute::Integer(
              attribute_name: 'priority',
            )
            DIV(class: 'row form-group') do
              LABEL(class: 'col-md-3 col-form-label control-label') do
                I18n.t('activerecord.attributes.dynamic/transaction/applicable_amount/rule.amount_type')
              end
              DIV(class: 'col-md-9') do
                SELECT(class: 'form-control', value: @amount_klass.name.underscore) do
                  ['discount', 'fee'].each do |t|
                    OPTION(value: t.classify) do
                      I18n.t("activerecord.values.dynamic/transaction/applicable_amount/rule.amount_type.#{t}")
                    end
                  end
                end.on(:change) do |e|
                  n = e.target.value.classify
                  @amount_klass = schema.klasses.detect {|k| k.name == n}
                  mutate
                end
              end
            end
            Form::Element::Association::BelongsTo(
              attribute_name: 'amount_id',
              target_klass_url: @amount_klass.collection_path,
              target_klass: @amount_klass,
            )
            Form::Element::Association::BelongsTo(
              attribute_name: 'target_id',
              target_klass_url: product_klass.collection_path,
              target_klass: product_klass,
              help: I18n.t('activerecord.attributes.dynamic/transaction/applicable_amount/rule.target_help')
            )
            Form::Element::Association::HasMany(mode: 'nested_form', attribute_name: 'conditions') do
              Form::Element::Layout::Row() do

                Form::Element::Layout::Column(col_size: 'col-4') do
                  Form::Element::Attribute::Array(
                    attribute_name: 'instance_field',
                    accept_empty_value: false,
                    selectable_expandable_option: false,
                    record_klass: schema_klass,
                    possible_values: possible_values_for_instance_field,
                    requirement: 'mandatory',
                    show_label: false
                  ).on(:change) do |attr, form, element|
                    element_prefix_path = element.prefix_path
                    method_names = attr.split('.')
                    new_value_type = attr_type(method_names, klass)&.underscore
                    old_value_type = form.submission.read(element_prefix_path + ['expression_value_type'])
                    if new_value_type != old_value_type
                      form.submission.write_from_user(element_prefix_path + ['expression_value'], nil)
                    end
                    form.submission.write_from_user(element_prefix_path + ['expression_value_type'], new_value_type)
                    mutate
                  end
                end

                Form::Element::Layout::Column(col_size: 'col-4') do
                  Form::Element::Layout::Condition(instance_field: {neq: ''}) do
                    Form::Element::Attribute::Enum(
                      attribute_name: 'expression_method',
                      possible_values: Proc.new do |form, path|
                        current_instance_field = form.submission.read(path + ['instance_field'])
                        if current_instance_field.present?
                          # FIXME on first render, instance_field is a 2d array for some reason
                          current_instance_field = current_instance_field.first if current_instance_field.first.is_a?(Array)
                          possible_values_for_expression_method(current_instance_field)
                        else
                          []
                        end
                      end,
                      show_label: false,
                    )
                  end
                end

                Form::Element::Layout::Column(col_size: 'col-4') do
                  Form::Element::Layout::Condition(proc: expression_value_condition_proc('Enum')) do
                    Form::Element::Attribute::Enum(
                      attribute_name: 'expression_value',
                      possible_values: Proc.new do |form, path|
                        current_instance_field = form.submission.read(path + ['instance_field'])
                        target_klass = klass_from_method_names(current_instance_field, klass)
                        target_schema_klass = schema.klasses.detect {|k| k.name == target_klass.name.demodulize}
                        enum_values_from_attr(current_instance_field.last, target_schema_klass)
                      end,
                      requirement: 'mandatory',
                      show_label: false
                    )
                  end

                  Form::Element::Layout::Condition(proc: expression_value_condition_proc('DateTime')) do
                    Form::Element::Attribute::Date(
                      attribute_name: 'expression_value',
                      requirement: 'mandatory',
                      show_label: false
                    )
                  end

                  Form::Element::Layout::Condition(
                    proc: Proc.new do |record, form|
                      next false unless record.instance_field.present? && record.expression_method.present?
                      !['Enum', 'DateTime', 'Uuid'].include?(attr_type(record.instance_field, klass))
                    end
                  ) do
                    Form::Element::Attribute::String(
                      attribute_name: 'expression_value',
                      requirement: 'mandatory',
                      show_label: false,
                    )
                  end
                end
              end
            end
            Form::Element::Control::AddButton(attribute_name: 'conditions')
          end.on(:success) do
            App.history.push(record_location)
          end
        end

        def footer
          form_footer
        end

        def init
          observe record
          if record != @previous_record
            @previous_record = record
            mutate
          end
        end

        def possible_values_for_instance_field
          @possible_values_for_instance_field ||= Proc.new do |klass, prefix|
            results = []

            klass.attrs.each do |attr|
              attrs = {
                label: klass.const.human_attribute_name(attr.name),
                value: "#{prefix}#{attr.name}",
              }
              results << attrs
            end

            klass.associations.each do |asso|
              k = asso.target_klass
              next unless k
              results << {
                label: klass.const.human_attribute_name(asso.name),
                value: "#{prefix}#{asso.name}.",
                klass: k,
              }
            end

            results
          end
        end

        def expression_value_condition_proc(type)
          Proc.new do |record, form|
            next false unless record.instance_field.present? && record.expression_method.present?
            attr_type(record.instance_field, klass) == type
          end
        end

        def product_klass
          @product_klass ||= record.class.reflect_on_association('target').klass
        end

        def attr_type(method_names, initial_klass)
          return initial_klass.attributes.dig(method_names[0], 'type') if method_names.length == 1
          association_klass = initial_klass.reflect_on_association(method_names[0])&.klass
          return attr_type(method_names[1..-1], association_klass) if association_klass
        end

        def possible_values_for_expression_method(instance_field)
          operations = ::Dynamic::Transaction::ApplicableAmount::Condition::AUTHORIZED_METHODS_BY_TYPE[attr_type(instance_field, klass)&.underscore]
          return [] unless operations
          return operations.map {|o| {value: o, label: I18n.t("crm.filters_op.#{TRANSLATION_KEY_BY_OPERATION[o]}")}}
        end

        def enum_values_from_attr(attr_name, klass)
          return [] unless attr_name
          attr = klass.attrs.detect{ |a| a.name == attr_name }
          return unless attr&.type == 'Enum'
          observe enum_values = Dynamic::Schema::Attribute::Enum::Value.where(
            attr_id: attr.name,
            schema_id: request.params[:schema_id],
            klass_id: klass.id
          ).all
          enum_values.map { |val| { value: val.name, label: val.human_name } }
        end

        def klass_from_method_names(method_names, klass)
          method_names = [method_names] if method_names.is_a?(String)
          return klass if method_names.length == 1
          return klass_from_method_names(method_names[1..-1], klass.reflect_on_association(method_names[0])&.options[:class_name].safe_constantize)
        end

      end
    end
  end
end