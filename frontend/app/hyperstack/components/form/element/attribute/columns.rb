require 'components/form/element/attribute/multiple_enum'

class Form
  module Element
    module Attribute
      class Columns < MultipleEnum

        param :show_select_all, default: false

        render { content }

        def checkboxes
          ::Crm::Table::Column::Selector(
            selected_columns: current_selected_columns,
            klass: column_klass
          ).on(:change) do |selecteds|
            @local_selected_columns = selecteds
            change_value(selecteds)
          end
          if show_select_all
            DIV(class: 'd-flex justify-content-start mb-2 mt-2') do
              select_all_button
            end
          end
        end

        def select_all_button
          is_all_selected = (current_selected_columns.length == all_paths.length) && all_paths.any?
          BUTTON(class: "btn btn-light", type: "button") do
            is_all_selected ? I18n.t('shared.deselect_all') : I18n.t('shared.select_all')
          end.on(:click) do
            @local_selected_columns = is_all_selected ? [] : all_paths.dup
            change_value(@local_selected_columns)
          end
        end

        def all_paths
          @all_paths ||= ::Crm::Table::Column::Selector.all_paths_for(column_klass)
        end

        def current_selected_columns
          @local_selected_columns ||= form&.submission&.read(path) || []
        end

        def column_klass
          record.klass_name.safe_constantize
        end
      end
    end
  end
end