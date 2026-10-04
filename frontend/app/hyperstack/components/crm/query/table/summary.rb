class Crm
  module Query
    module Table
      class Summary < Form::Element::Base

        param :klass
        param :chart_columns, default: nil

        render { content }

        def render_input
          layout_input do
            cols = selected_columns
            if cols.blank?
              I18n.t('shared.none_f')
            else
              current_value = form.submission.read(path) || {}
              DIV do
                cols.each do |col_name|
                  col = klass&.datatable_column_by_name.try(:[], col_name)
                  next unless col
                  col_op = current_op_for_column(col, current_value)

                  DIV(class: 'row mb-2 align-items-center') do
                    DIV(class: 'col-4') do
                      LABEL(class: 'mb-0') { col.human_path.join(' > ') }
                    end
                    DIV(class: 'col-8') do
                      SELECT(class: 'form-control form-control-sm', value: col_op) do
                        col.summary_operations.each do |op|
                          OPTION(value: op) do
                            op_symbol = I18n.t("crm.datatable.summary.operations.#{op}.symbol", default: op)
                            op_label = I18n.t("crm.datatable.summary.operations.#{op}.label", default: op.humanize)
                            "#{op_symbol} #{op_label}"
                          end
                        end
                      end.on(:change) do |event|
                        update_column_op(col, event.target.value.to_s)
                      end
                    end
                  end
                end
              end
            end
          end
        end

        def selected_columns
          chart_columns || form.submission.read(path[0..-2] + ['columns'])
        end

        def current_op_for_column(col, value)
          config = value[col.name.to_s]
          ops = case config
            when Array then config
            when Hash then config[:ops] || []
            else []
            end
          Array(ops).first || col.default_summary_operation
        end

        def update_column_op(col, new_op)
          default_op = col&.default_summary_operation
          current = (form.submission.read(path) || {}).dup
          if new_op == default_op
            current.delete(col.name.to_s)
          else
            current[col.name.to_s] = { 'ops' => [new_op] }
          end
          change_value(current.presence)
          mutate
        end

        def displayed_label
          I18n.t('crm.query.params.table.summary')
        end

        def change_value(value)
          return unless form && !form.reseting?
          old_value = form.submission.read(path)
          if value != old_value
            form.enable
            form.submission.write_from_user(path, value)
            change_data(value)
            mutate
            change!(value, form, self)
            form.change
          end
        end
      end
    end
  end
end