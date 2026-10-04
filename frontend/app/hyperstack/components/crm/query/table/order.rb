class Crm
  module Query
    module Table
      class Order < Form::Element::Base

        param :klass
        param :chart_columns, default: nil

        render { content }

        def render_input
          layout_input do
            if selected_columns
              orders = normalized_value
              if orders.any?
                orders.each_with_index do |pair, index|
                  DIV(key: "order-#{index}", class: 'row mb-2 align-items-center') do
                    DIV(class: 'col-auto pr-0') do
                      SPAN(class: 'badge badge-light rounded-circle justify-content-center', style: {width: '20px', height: '20px'}) do
                        (index + 1).to_s
                      end
                    end
                    DIV(class: 'col') do
                      column_select(pair, index)
                    end
                    DIV(class: 'col') do
                      direction_select(pair, index)
                    end
                    DIV(class: 'col-auto pl-0') do
                      BUTTON(class: 'btn btn-sm btn-light', type: 'button') do
                        I(class: 'fa fa-trash')
                      end.on(:click) do |event|
                        event.prevent_default
                        remove_order(index)
                      end
                    end
                  end
                end
              else
                DIV(class: 'mb-2') do
                  I18n.t('shared.none_f')
                end
              end
              if available_columns_for_add.any?
                BUTTON(class: 'btn btn-sm btn-light', type: 'button') do
                  I(class: 'fa fa-plus')
                end.on(:click) do |event|
                  event.prevent_default
                  add_order
                end
              end
            else
              I18n.t('shared.none_f')
            end
          end
        end


        def selected_columns
          cols = chart_columns || form.submission.read(path[0..-2] + ['columns'])
          return unless cols
          result = cols.select { |col| klass.datatable_column_by_name[col].present? }
          result
        end

        def normalized_value
          v = form.submission.read(path)
          return [] if v.nil? || v.empty?
          if v[0].is_a?(String)
            return v[0].present? ? [v] : []
          end
          v.select { |pair| pair.is_a?(Array) && pair[0].present? }
        end

        def available_columns_for_add
          used = normalized_value.map { |pair| pair[0] }
          selected_columns.select { |col| !used.include?(col) }
        end

        def column_select(pair, index)
          current_col = pair[0].to_s
          used_by_others = normalized_value.each_with_index
            .select { |_, i| i != index }
            .map { |p, _| p[0] }
          available = selected_columns.select { |col| !used_by_others.include?(col) }

          SELECT(class: 'form-control', value: current_col) do
            OPTION(value: '') { '' }
            available.each do |col|
              OPTION(value: col) { column_label(col) }
            end
          end.on(:change) do |event|
            update_order_at(index, event.target.value, pair[1] || 'asc')
          end
        end

        def direction_select(pair, index)
          current_dir = pair[1].to_s
          SELECT(class: 'form-control', value: current_dir) do
            ['asc', 'desc'].each do |dir|
              OPTION(value: dir) do
                I18n.t("activerecord.values.dynamic/form/element/base.sorting_type.#{dir}")
              end
            end
          end.on(:change) do |event|
            update_order_at(index, pair[0], event.target.value)
          end
        end

        def add_order
          orders = normalized_value.dup
          first_available = available_columns_for_add.first
          return unless first_available
          orders << [first_available, 'asc']
          change_value(orders)
          mutate
        end

        def remove_order(index)
          orders = normalized_value.dup
          orders.delete_at(index)
          change_value(orders)
          mutate
        end

        def update_order_at(index, col, dir)
          orders = normalized_value.dup
          if col.present?
            orders[index] = [col, dir]
          else
            orders.delete_at(index)
          end
          change_value(orders)
          mutate
        end

        def column_label(col)
          return unless col
          r = []
          k = klass
          col.split('.').each do |c|
            clean = c.gsub('[]', '')
            next unless k
            r << k.human_attribute_name(clean)
            if k.reflect_on_association(clean)
              k = k.reflect_on_association(clean).klass
            end
          end
          r.join(' > ')
        end

        def displayed_label
          I18n.t('crm.query.params.table.order')
        end

        def convert_value(value)
          r = super
          if r.is_a?(::Array)
            r = r.select { |pair| pair.is_a?(Array) && pair[0].present? }
          end
          r
        end

        def change_value(value)
          return unless form && !form.reseting?
          old_value = form.submission.read(path)
          new_value = convert_value(value)
          if new_value != old_value
            form.enable
            form.submission.write_from_user(path, new_value)
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
