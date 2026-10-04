class Settings
  class Schema
    class Redirections < ::Settings::Schema::Base

      render { content }

      def klass
        ::Dynamic::Redirection
      end

      def new_record
        klass.new({
          schema_id: match.params['schema_id'],
        })
      end

      class EditPanel < ::Settings::Schema::EditPanel

        render { content }

        def form
          Form(record: record) do
            Form::Element::Attribute::String(
              attribute_name: 'name',
              auto_focus: true,
            )
            Form::Element::Association::BelongsTo(
              attribute_name: 'klass_id',
            ).on(:change) do
              mutate
            end
            Form::Element::Attribute::Enum(
              attribute_name: 'condition_type',
            )
            HR{}
            DIV(class: 'mb-3') do
              record.class.human_attribute_name('target')
            end
            target_params(:target)
            HR{}
            DIV(class: 'mb-3') do
              record.class.human_attribute_name('fallback')
            end
            target_params(:fallback)
          end.on(:success) do
            App.history.push(record_location)
          end
        end

        def target_params(kind)
          kind_type = "#{kind}_type"
          kind_klass_id = "#{kind}_klass_id"
          kind_params = "#{kind}_params"
          kind_formula = "#{kind}_formula"

          Formula(
            attribute_name: kind_formula,
            help: record.class.human_attribute_name("#{kind_formula}_help"),
            help_position: 'icon',
            schema: schema,
          )
          Form::Element::Attribute::Enum(
            attribute_name: kind_type,
          )
          Form::Element::Layout::Condition(kind_type => 'Form') do
            Form::Element::Association::BelongsTo(
              attribute_name: "#{kind}_klass_id",
            ).on(:change) do |value, form|
              clear(form, kind)
              mutate
            end
            Form::Element::Attribute::Hash(
              attribute_name: kind_params,
              mode: 'nested_form',
            ) do
              Form::Element::Attribute::Enum(
                attribute_name: 'record_as',
                default_value: 'source',
                possible_values: ['source', 'target'].map do |v|
                  {value: v, label: record.class.human_attribute_value(:record_as, v)}
                end
              ).on(:change) do |value, form|
                clear(form, kind)
                mutate
              end
              Form::Element::Association::BelongsTo(
                attribute_name: 'form_id',
                target_relation: Dynamic::Form.where(schema_id: record.schema_id),
                autocomplete_filters: {
                  klass_name: { variable: kind_klass_id },
                },
                convert_autocomplete_variable: convert_autocomplete_variable(kind_klass_id),
              )
            end
          end
          Form::Element::Layout::Condition(kind_type => 'Vcard') do
          end
        end

        def convert_autocomplete_variable(kind_klass_id)
          @convert_autocomplete_variables ||= {}
          @convert_autocomplete_variables[kind_klass_id] ||= Proc.new do |k, v|
            next v unless k == kind_klass_id
            next v ? schema.klasses_by_id[v]&.const_absolute_name : nil
          end
        end

        def clear(form, kind)
          form.submission.write(['redirection', "#{kind}_params", 'form_id'], nil)
          form.submission.write(['redirection', "#{kind}_params", 'form_params'], {})
        end

        def footer
          form_footer
        end

      end

    end

  end
end
