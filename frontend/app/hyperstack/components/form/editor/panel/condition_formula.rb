require 'components/form/element/base'
class Form
  class Editor
    module Panel
      class ConditionFormula < ::Form::Element::Base

        param :get_elements_path, default: nil
        param :get_variable, default: nil
        param :klass

        collect_other_params_as :other_params

        def render_input
          layout_input do
            value = form.submission.read(path)
            if @list.blank? || value != @old_value
              @list = AdvancedList.convert_from_hash(value, klass, name_without_brackets: true, normalize: true)
              @old_value = value
            end

            AdvancedList(
              list: @list,
              klass: klass,
              root_klass: klass,
              get_variable: get_variable,
              get_elements_path: get_elements_path,
              enable_default_filters: false,
            ).on(:change) do |list|
              @list = list
              hash = AdvancedList.convert_to_hash(list, normalize: true)
              change_value(hash)
              @old_value = hash
              mutate
            end
          end
        end

        def layout_input
          DIV(class: 'row') do
            DIV(class: 'col') do
              DIV(class: 'form-group') do
                LABEL do
                  'Condition'
                end
                yield
              end
            end
          end
        end

        class AdvancedList < ::Crm::Filters::AdvancedList
          param :get_elements_path

          render { content }

          def column_possible_values
            return @column_possible_values if @column_possible_values
            attrs = klass.attribute_names.select do |a|
              !['created_at', 'deleted_at', 'updated_at'].include?(a) && !klass.reflect_on_association(a.gsub(/_id$/, ''))
            end
            @column_possible_values = attrs.map do |attr|
              column = self.class.find_column(klass, attr)
              {label: column.human_path.join(' > '), value: column}
            end
          end

          def self.find_column(klass, path)
            @find_columns ||= {}
            @find_columns[klass] ||= {}
            result =  @find_columns.dig(klass, path)
            return result if result

            root_klass = klass
            path_ = path.split('.')
            name = path_.pop
            path_.each do |attr_or_assoc|
              next unless klass
              reflection = klass.reflect_on_association(attr_or_assoc)
              klass = reflection.klass if reflection
            end
            return unless klass

            klass.reflect_on_all_attachments # TODO fix reflect_on_association is called before reflect_on_all_attachments (in hyper_resource)
            column_klass = ::Crm::Datatable::Column.klass_from_method_name(klass, name)
            return unless column_klass

            @find_columns[klass] ||= {}
            @find_columns[klass][path] = column_klass.new(name: path, klass: klass, root_klass: root_klass, path: path_, depth: path_.length, method_name: name)
          end

          class List < ::Crm::Filters::List
          end
        end

      end
    end
  end
end
