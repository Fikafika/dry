require 'components/form/element/base'

class Settings
  class Schema
    class Associations
      class DefaultOrder < ::Form::Element::Base

        param :klass
        param :root_klass

        render { content }

        def render_input
          observe klass.options_for_indexed_json
          layout_input do
            next unless klass.options_for_indexed_json.loaded?
            orders = normalized_value
            DIV(class: 'd-flex flex-column') do
              if orders.any?
                orders.each_with_index do |pair, index|
                  render_row(pair, index)
                end
              else
                DIV(class: 'mb-2 text-muted') do
                  I18n.t('shared.none_f')
                end
              end
              render_add_button if available_attributes_for_add.any?
            end
          end
        end

        def render_row(pair, index)
          DIV(key: "order-#{index}", class: 'row mb-2 align-items-center') do
            DIV(class: 'col-auto pr-0') do
              SPAN(class: 'badge badge-light rounded-circle justify-content-center', style: {width: '20px', height: '20px'}) do
                (index + 1).to_s
              end
            end
            DIV(class: 'col') do
              attribute_select(pair, index)
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

        def attribute_select(pair, index)
          current = pair[0].to_s
          used_by_others = normalized_value.each_with_index
            .select { |_, i| i != index }
            .map { |p, _| p[0] }
          available = attribute_options.reject { |name, _| used_by_others.include?(name) }
          SELECT(class: 'form-control', value: current) do
            OPTION(value: '') { '' }
            available.each do |name, label|
              OPTION(value: name) { label }
            end
          end.on(:change) do |event|
            update_order_at(index, event.target.value, pair[1] || 'asc')
          end
        end

        def direction_select(pair, index)
          SELECT(class: 'form-control', value: pair[1].to_s) do
            ['asc', 'desc'].each do |dir|
              OPTION(value: dir) do
                I18n.t("activerecord.values.dynamic/form/element/base.sorting_type.#{dir}")
              end
            end
          end.on(:change) do |event|
            update_order_at(index, pair[0], event.target.value)
          end
        end

        def render_add_button
          BUTTON(class: 'btn btn-sm btn-light align-self-start', type: 'button') do
            I(class: 'fa fa-plus mr-1')
            I18n.t('shared.add')
          end.on(:click) do |event|
            event.prevent_default
            add_order
          end
        end

        def add_order
          first = available_attributes_for_add.first
          return unless first
          change_value(normalized_value + [[first.first, 'asc']])
          mutate
        end

        def remove_order(index)
          orders = normalized_value.dup
          orders.delete_at(index)
          change_value(orders)
          mutate
        end

        def update_order_at(index, name, dir)
          orders = normalized_value.dup
          if name.present?
            orders[index] = [name, dir]
          else
            orders.delete_at(index)
          end
          change_value(orders)
          mutate
        end

        def normalized_value
          v = form.submission.read(path)
          return [] if v.nil? || v.empty?
          return v[0].present? ? [v] : [] if v[0].is_a?(String) # legacy single flattened pair
          v.select { |pair| pair.is_a?(::Array) && pair[0].present? }
        end

        def available_attributes_for_add
          used = normalized_value.map { |pair| pair[0] }
          attribute_options.reject { |name, _| used.include?(name) }
        end

        def attribute_options
          names = (klass.try(:attribute_names) || []).reject { |a| a.start_with?('_') }
          names.map { |a| [a, klass.human_attribute_name(a)] }.sort_by { |_, label| label.to_s }
        end

        def convert_value(value)
          r = super
          r = r.select { |pair| pair.is_a?(::Array) && pair[0].present? } if r.is_a?(::Array)
          r
        end

        def displayed_label
          I18n.t('activerecord.attributes.dynamic/schema/association/base.default_elasticsearch_order')
        end

      end
    end
  end
end
