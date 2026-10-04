class Layout
  class Editor
    module Panel
      module Crm
        module Sheet
          module Datatable
            class Base < Panel::Base
              include Associations

              collect_other_params_as :other_params

              render { content }

              def parameters
                columns_parameters
              end

              def columns_parameters
                klass = klass_for_table
                observe klass&.options_for_indexed_json
                return unless klass&.options_for_indexed_json&.loaded?
                ::Crm::Query::Table::Columns(attribute_name: 'columns', klass: klass)
                ::Crm::Query::Table::Order(attribute_name: 'order', klass: klass)
                ::Form::Element::Attribute::Hash(
                  attribute_name: 'width',
                  label: I18n.t('crm.query.params.table.width'),
                  label_for_key: Proc.new do |key|
                    klass&.datatable_column_by_name.try(:[], key)&.human_path&.join(' > ')
                  end,
                  hidden_keys: Proc.new do |form|
                    (form.submission.params.dig('element', 'component_params', 'columns') || []) - (form.submission.params.dig('element', 'component_params', 'width')&.keys || [])
                  end,
                  default_value_for_key: 150,
                  values_type: 'number',
                  allow_remove: true,
                )
                ::Form::Element::Attribute::Enum(
                  attribute_name: 'locked',
                  label: I18n.t('crm.query.params.table.locked'),
                  possible_values: Proc.new do |form|
                    columns = form.submission.params.dig('element', 'component_params', 'columns') || []
                    columns.map{|key| {value: key, label: klass&.datatable_column_by_name.try(:[], key)&.human_path&.join(' > ') } }
                  end,
                )
              end

              def klass_for_table
                a = association_name
                return unless a
                return klass_name.constantize.reflect_on_association(a).klass
              end

              def association_name
                return unless schema_klass && record.component_params_converter_options
                schema_klass.associations.detect {|k| k.id == record.component_params_converter_options[:schema_association]}&.name
              end

              def params_converter_parameters
                ::Form::Element::Attribute::Hash(
                  attribute_name: 'component_params_converter_options',
                  mode: 'nested_form'
                ) do
                  association_id
                end
              end

              def association_id
                ::Form::Element::Attribute::Enum(
                  attribute_name: 'schema_association',
                  label: I18n.t('activerecord.models.dynamic/schema/association/base.one'),
                  possible_values: possible_inverse_associations,
                )
              end

            end
          end
        end
      end
    end
  end
end
