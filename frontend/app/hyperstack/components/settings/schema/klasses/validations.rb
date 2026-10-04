class Settings

  class Schema

    class Validations < Klasses::Base

      render { content }

      def klass
        ::Dynamic::Schema::Validation::Base
      end

      def new_record
        klass.new({
          schema_id: match.params['schema_id'],
          klass_id: match.params['klass_id'],
        })

      end

      def self.includes_for_all
        { include: { attrs: {include: {translation: 1}}, attr: {include: {translation: 1}}, comparison_attr: {include: {translation: 1}}} }
      end

      def schema_klass
        observe @schema_klass = Dynamic::Schema::Klass.includes({attrs: {includes: {translations: 1}}}).where(schema_id: match.params['schema_id']).find(match.params['klass_id'])
      end

      def edit_panel
        EditPanel(record: current_model, path: "#{index_location}/:id", schema: schema, schema_klass: schema_klass)
      end

      class EditPanel < ::Settings::Schema::EditPanel

        render { content }
        param :schema_klass, default: nil

        def header
          ::Stackable::Toolbar() do
            ::Stackable::PageHeader(title: I18n.t('shared.new'), back: back_location)
          end
        end


        def format_examples
          "
          - #{I18n.t('settings.validations.format_examples.zip_code')} \\A[0-9]{5}\\z<br/>
          - #{I18n.t('settings.validations.format_examples.at_least_one_char_and_uppercase')} \\A[A-Z]+\\z<br/>
          - #{I18n.t('settings.validations.format_examples.nhs_number')} \\A[12][0-9]{12}\\z
          "
        end

        def form
          Form(record: record) do
            Form::Element::Attribute::TranslatableString(
              attribute_name: 'human_name',
              errors_from: 'name',
              auto_focus: true,
            )
            Form::Element::Attribute::Enum(
              attribute_name: 'type',
              possible_values: validation_subclasses,
              disabled: record.persisted?,
            )
            additional_fields
            Form::Element::Layout::Condition(type: ['Dynamic::Schema::Validation::Format::Base']) do
              Form::Element::Attribute::String(
                attribute_name: 'expression',
                editor: 'textarea',
                help: format_examples,
                help_position: 'icon'
              )
            end
            Form::Element::Layout::Condition(type: ['Dynamic::Schema::Validation::Comparison::Value', 'Dynamic::Schema::Validation::Comparison::Attribute']) do
              Form::Element::Attribute::Enum(
                attribute_name: 'operator',
              )
            end
            Form::Element::Layout::Condition(type: ['Dynamic::Schema::Validation::Comparison::Value']) do
              Form::Element::Layout::Condition(attr_type: ['String', 'TranslatableString', 'TranslatableText']) do
                Form::Element::Attribute::String(
                  attribute_name: 'comparison_value',
                )
              end
              Form::Element::Layout::Condition(attr_type: ['Float']) do
                Form::Element::Attribute::Float(
                  attribute_name: 'comparison_value',
                )
              end
              Form::Element::Layout::Condition(attr_type: ['Integer']) do
                Form::Element::Attribute::Integer(
                  attribute_name: 'comparison_value',
                )
              end
              Form::Element::Layout::Condition(attr_type: ['Text']) do
                Form::Element::Attribute::Text(
                  attribute_name: 'comparison_value',
                )
              end
              Form::Element::Layout::Condition(attr_type: ['TimeOfDay']) do
                Form::Element::Attribute::TimeOfDay(
                  attribute_name: 'comparison_value',
                )
              end
              Form::Element::Layout::Condition(attr_type: ['DateTime']) do
                Form::Element::Attribute::DateTime(
                  attribute_name: 'comparison_value',
                )
              end
              Form::Element::Layout::Condition(attr_type: ['Date']) do
                Form::Element::Attribute::Date(
                  attribute_name: 'comparison_value',
                )
              end
            end
            Form::Element::Layout::Condition(type: ['Dynamic::Schema::Validation::Comparison::Attribute']) do
              Form::Element::Association::BelongsTo(
                attribute_name: 'comparison_attr_id',
              )
            end
            Form::Element::Layout::Condition(type: ['Dynamic::Schema::Validation::AnyPresence']) do
              Form::Element::Association::HasMany(
                attribute_name: 'attr_ids',
                disabled: record.persisted?,
              )
            end
            comment
          end.on(:success) do
            App.history.push(record_location)
          end
        end

        def additional_fields
          Form::Element::Layout::Condition(type: {neq: 'Dynamic::Schema::Validation::AnyPresence'}) do
            if record.new_record?
              Form::Element::Association::BelongsTo(
                attribute_name: 'attr_id',
              ).on(:change) do |attr, form|
                form.submission.write_from_user(['validation','attr_type'], attr&.type || '')
              end
              Form::Element::Attribute::String(
                attribute_name: 'attr_type',
                editor: "hidden",
              )
            else
              Form::Element::Association::BelongsTo(
                attribute_name: 'attr',
                disabled: true,
              )
            end
          end
        end

        def footer
          form_footer
        end

        def validation_subclasses
          ::Dynamic::Schema::Validation::Base.subclasses.map do |klass|
            {
              value: klass.name,
              label: klass.try(:model_name).try(:human) || klass.name,
            }
          end
        end

      end

    end
  end
end
