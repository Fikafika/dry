class Settings
  class Schema
    class MailRules < Klasses::Base

      before_update do
        message_klass = schema.features.detect{|f| f.name == self.class.feature}.concerns.detect{|c| c.name == 'Message'}.klass
        unless message_klass && schema_klass.associations.any?{|a| a.target_klass_id == message_klass.id }
          App.history.push(location.split('/')[0..-2].join('/'))
        end
      end

      render { content }

      def self.feature
        "Dynamic::MailHosting::Feature"
      end

      def self.icon
        ::Dynamic::MailHosting::Rule.icon
      end

      def self.model_name
        ::Dynamic::MailHosting::Rule.model_name
      end

      def self.disabled?(klass, schema)
        message_klass = schema.features.detect{|f| f.name == self.feature}.concerns.detect{|c| c.name == 'Message'}.klass
        !(message_klass && klass.associations.any?{|a| a.target_klass_id == message_klass.id })
      end

      def klass
        Dynamic::MailHosting::Rule
      end

      def new_record
        klass.new({
          klass_name: schema_klass_name,
          name: "",
          conditions: [
            Dynamic::MailHosting::Condition.new(
              attr: '',
              operator: '',
              value: ''
            )
          ]
        })
      end

      def self.includes_for_all
        { include: {conditions: 1} }
      end

      def scope_for_all
        {
          klass_name: schema_klass_name,
          schema_name: match.params['schema_id']
        }
      end

      def schema_klass_name
        "D::#{match.params['schema_id'].capitalize}::#{match.params['klass_id'].capitalize}"
      end

      def edit_panel
        EditPanel(record: current_model, path: "#{index_location}/:id", schema: schema, klass_name: schema_klass_name, schema_name: match.params['schema_id'])
      end

      class EditPanel < ::Settings::Schema::EditPanel

        param :klass_name, default: nil
        param :schema_name, default: nil

        before_render :init

        render { content }

        def header
          ::Stackable::Toolbar() do
            ::Stackable::PageHeader(title: record.new_record? ? I18n.t('shared.new') : record.name, back: back_location)
          end
        end

        def form

          Form(record: record) do
            Form::Element::Attribute::String(
              attribute_name: 'klass_name',
              default_value: klass_name,
              editor: 'hidden',
            )
            Form::Element::Attribute::String(
              attribute_name: 'schema_name',
              default_value: schema_name,
              editor: 'hidden',
            )
            Form::Element::Attribute::String(
              attribute_name: 'name',
              errors_from: 'name',
            )
            Form::Element::Association::HasMany(mode: 'nested_form', attribute_name: 'conditions', show_item_header: false, show_item_separator: false) do
              Form::Element::Layout::Row() do
                Form::Element::Layout::Column(col_size: "col-3") do
                  Form::Element::Attribute::Enum(
                    attribute_name: "attr",
                    possible_values: attr_values,
                    show_label: false,
                  )
                end
                Form::Element::Layout::Column(col_size: "col-3") do
                  Form::Element::Layout::Condition(attr: '') do
                    Form::Element::Attribute::Enum(
                      attribute_name: "operator",
                      possible_values: [],
                      show_label: false,
                    )
                  end
                  Form::Element::Layout::Condition(attr: 'subject') do
                    Form::Element::Attribute::Enum(
                      attribute_name: "operator",
                      possible_values: operator_values('subject'),
                      show_label: false,
                    )
                  end
                  Form::Element::Layout::Condition(attr: 'body') do
                    Form::Element::Attribute::Enum(
                      attribute_name: "operator",
                      possible_values: operator_values('body'),
                      show_label: false,
                    )
                  end
                  Form::Element::Layout::Condition(attr: 'mailbox') do
                    Form::Element::Attribute::Enum(
                      attribute_name: "operator",
                      possible_values: operator_values('mailbox'),
                      show_label: false,
                    )
                  end
                  Form::Element::Layout::Condition(attr: 'sender') do
                    Form::Element::Attribute::Enum(
                      attribute_name: "operator",
                      possible_values: operator_values('sender'),
                      show_label: false,
                    )
                  end
                  Form::Element::Layout::Condition(attr: 'recipients') do
                    Form::Element::Attribute::Enum(
                      attribute_name: "operator",
                      possible_values: operator_values('recipients'),
                      show_label: false,
                    )
                  end
                  Form::Element::Layout::Condition(attr: 'sent_at') do
                    Form::Element::Attribute::Enum(
                      attribute_name: "operator",
                      possible_values: operator_values('sent_at'),
                      show_label: false,
                    )
                  end
                end
                Form::Element::Layout::Column(col_size: "col-6") do
                  Form::Element::Attribute::String(
                    attribute_name: 'value',
                    placeholder: "formule",
                    show_label: false,
                  )
                end
              end
            end
            Form::Element::Control::AddButton(attribute_name: 'conditions')
          end.on(:success) do
            App.history.push(record_location)
          end
        end

        def attr_values
          attrs = ['subject', 'body', 'mailbox', 'sender', 'recipients', 'sent_at']
          attrs.map{|a| {label: a,value: a}}
        end

        def operator_values(attr)
          operation_by_attr = {
            subject: ['includes', 'eq', 'in'],
            body: ['includes'],
            mailbox: ['includes', 'eq', 'in'],
            sender: ['includes', 'eq', 'in'],
            recipients: ['includes', 'eq', 'in'],
            sent_at: ['eq', 'gt', 'gteq', 'lt', 'lteq'],
          }
          operation_by_attr[attr.to_sym]&.map{|o| {label: o,value: o}}
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

      end
    end
  end
end