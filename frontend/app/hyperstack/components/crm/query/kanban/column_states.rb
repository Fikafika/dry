class Crm
  module Query
    module Kanban
      class ColumnStates < Form::Element::Base

        param :klass
        param :column_attribute

        track_changes :klass, :column_attribute

        render { content }

        def content
          return unless possible_values
          Form::Element::Attribute::MultipleEnum(
            prefix_path: ['base'],
            attribute_name: 'value',
            editor: 'tom_select',
            form: fake_form,
            label: I18n.t('crm.query.params.kanban.column_states'),
            possible_values: possible_values,
          ).on(:change) do |v, form|
            change_value(enum_to_value(v))
          end
        end

        def possible_values
          return @possible_values if @possible_values
          return if @possible_values_loading
          @possible_values_loading = true
          compute_possible_values do |values|
            @possible_values = values
            @possible_values_loading = false
            mutate
          end
          return nil
        end

        def compute_possible_values
          result = [{ value: 'non-categorized-col', label: I18n.t("crm.kanban.not_categorized")}]
          if klass.attributes[column_attribute]
            klass.attributes.dig(column_attribute, 'possible_values', I18n.locale)&.each do |possible_value|
              result << {
                value: klass.attributes.dig(column_attribute, 'mapping', I18n.locale, possible_value[:label]),
                label: possible_value[:label],
              }
            end
            yield(result)
          elsif reflection = klass.reflect_on_association(column_attribute)
            name_attribute = klass.try(:name_attribute)
            reflection.klass.all do |records|
              result = records.map do |record|
                { value: record.id, label: (record.try(name_attribute) || record.id) }
              end
              yield(result)
            end
          end
          return result
        end

        def enum_value
          value_to_enum(form.submission.read(path))
        end

        def fake_form
          @fake_form = nil if klass_changed? || column_attribute_changed?
          return @fake_form if @fake_form
          @fake_form = Form::FakeForm.new
          @fake_form.submission.write_from_db(['base', 'value'], enum_value)
          return @fake_form
        end

        def value_to_enum(value)
          value.is_a?(::Hash) ? value.keys : []
        end

        def enum_to_value(enum_value)
          return unless enum_value.try(:any?)
          result = {}
          enum_value.each do |v|
            result[v] = 'OPEN'
          end
          return result
        end

      end
    end
  end
end
