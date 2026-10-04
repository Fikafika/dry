class Crm
  module Query
    module Table
      class Columns < Form::Element::Base

        param :klass
        param :prefix, default: nil

        render { content }

        def render_input
          return unless klass

          layout_input do
            value = form.submission.read(path)
            if @selected_columns.blank? || value != @selected_columns
              @selected_columns = value || []
            end
            Crm::Table::Column::Selector(selected_columns: @selected_columns, klass: klass, prefix: prefix).on(:change) do |selected_columns|
              @selected_columns = selected_columns
              change_value(selected_columns)
            end
          end
        end

        def displayed_label
          I18n.t('crm.query.params.table.columns')
        end

        def label_col_size
          'col-12'
        end

        def input_col_size
          'col-12'
        end

      end
    end
  end
end
