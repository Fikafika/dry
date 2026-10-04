# backtick_javascript: true
require 'components/crm/workflow/trigger_action'

class Crm
  module Chart
    class Table < Base
      include Crm::Workflow::TriggerAction

      render { content }

      def content
        layout do
          Crm::Datatable(
            id: table_id,
            klass: klass,
            search_query: search_query&.params,
            search_query_key: url_id,
            ajax: ajax,
            draw: @draw,
            height: height,
            width: other_params[:width],
            columns: other_params[:columns],
            summary: other_params[:summary],
            column_widths: other_params[:column_widths],
            locked_column: chart_table_locked,
            locked_column_right: chart_table_locked_right,
            order: chart_table_order,
            extra_menu_items: [
              {
                icon:  'fas fa-pencil-alt',
                label: I18n.t('crm.dashboard.edit_chart'),
                link:  "/crm/#{request.params[:schema]}/dashboards/#{dashboard_id}/charts/#{other_params[:record]&.id}/edit",
                panel: 'right'
              }
            ],
          ).on(:init) do |datatable|
            @datatable = datatable
          end.on(:launch_search) do
            search
          end.on(:column_locked) do |column|
            apply_lock(:locked_column, column)
          end.on(:column_locked_right) do |column|
            apply_lock(:locked_column_right, column)
          end.on(:columns_reordered) do |columns|
            other_params[:record].update({columns: columns}, {update_dashboard: false})
          end.on(:columns_resized) do |column_widths|
            other_params[:record].update({column_widths: column_widths}, {update_dashboard: false})
          end.on(:column_deleted) do |column|
            if other_params[:columns]
              cols = other_params[:columns].select{|c| c != column}
              other_params[:record].columns = cols
              other_params[:record].update({columns: cols}, {update_dashboard: false})
              mutate
            end
          end.on(:order_changed) do |order|
            if search_query
              search_query[url_id] ||= {}
              search_query[url_id][:order] = order
            end
            search
          end.on(:edit_all) do |params|
            selection = get_selection_info
            props[:on_edit_all]&.call(params, selection[:all_selected], selection[:selected_ids])
          end.on(:merge_all) do
            selection = get_selection_info
            props[:on_merge_all]&.call(selection[:all_selected], selection[:selected_ids])
          end.on(:copy_all) do
            selection = get_selection_info
            props[:on_copy_all]&.call(selection[:all_selected], selection[:selected_ids])
          end.on(:export_all) do
            selection = get_selection_info
            props[:on_export_all]&.call(selection[:all_selected], selection[:selected_ids])
          end.on(:delete_all) do
            selection = get_selection_info
            props[:on_delete_all]&.call(selection[:all_selected], selection[:selected_ids])
          end.on(:action_click) do |data|
            execute_trigger_action(data)
          end.on(:summary_changed) do |col_name, new_op|
            sq = search_query&.params
            next unless sq
            chart_section = sq[url_id]
            if chart_section
              chart_section[:summary] ||= {}
              chart_section[:summary][col_name] = { ops: [new_op] }
            end
            table_section = sq[:table]
            if table_section
              table_section[:summary] ||= {}
              table_section[:summary][col_name] = { ops: [new_op] }
            end
            search
          end
        end
      end

      def init
        registry&.register(uuid, self)
      end

      def fullscreen_applicable?
        false
      end

      def search_applicable?
        false
      end

      def get_selection_info
        datatable_component = ::Element.find("##{table_id}").data('get_component').call
        {
          all_selected: datatable_component.all_selected?,
          selected_ids: datatable_component.selected_rows_ids
        }
      end

      def reset_selection
        node = ::Element.find("##{table_id}")
        return unless node.length > 0
        datatable_component = node.data('get_component')&.call
        datatable_component&.reset_selection
      end

      def klass
        other_params[:klass_name]&.safe_constantize
      end

      def ajax
        return Proc.new do |data, callback, settings|
          data = Hash.new(data)
          @ajax_data = data
          search_data = {
            time_zone: `Intl.DateTimeFormat().resolvedOptions().timeZone`,
            search_query: search_query.dump,
            dashboard_id: dashboard_id,
          }
          HyperResource::HTTP.post("#{klass.api_path}/data", payload: {
            datatable: data.merge(search_data),
            dashboard: search_data,
          }).then do |response|
            registry&.response = response.json['dashboard']
            if registry
              if registry&.render_all?
                # first ajax executed by first render of datatable
                # so we must render other charts
                registry.render_all
              else
                registry.redraw_all
              end
            end
            callback.call(response.json['datatable']&.to_n)
          end
        end.to_n
      end

      def search
        redraw_datatable
        registry.search
      end

      after_new_params do
        if klass && @previous_uuid != uuid
          @previous_uuid = uuid
        end
      end

      def chart_table_order
        sq = search_query&.dig(url_id)
        sq[:order] if sq.is_a?(Hash)
      end

      def apply_lock(record_attr, column)
        other_params[:record].send("#{record_attr}=", column)
        other_params[:record].update({record_attr => column}, {update_dashboard: false})
        mutate
      end

      def chart_table_locked
        other_params[:record]&.locked_column
      end

      def chart_table_locked_right
        other_params[:record]&.locked_column_right
      end

      def search_query
        return registry.search_query
      end

      def dashboard_id
        return registry.dashboard_id
      end

      def redraw_datatable
        @draw ||= 0
        @draw += 1
      end

      def table_id
        "table-#{uuid}"
      end

      track_changes :search_query_filters

      def search_query_filters
        registry&.search_query&.dig('filters')
      end

      def load_charts_data(reload: false)
        return unless @datatable

        if !reload && (registry && registry.render_all? || !registry.search_query_params_changed?)
          # prevent initial ajax because datatable already do it
          return
        else
          callback = Proc.new do
            yield if block_given?
          end.to_n
        end

        if !search_query_filters_changed?
          `#{@datatable.to_n}.ajax.reload(callback)` # TODO how to use draw instead of reload ?
        end
      end

      def filters
      end

      def reset_filter_btn
        A(href: '#reset', class: 'reset btn btn-sm btn-light', style: { display: (search_query&.dig(:filters)&.any? ? '' : 'none') }) do
          I(class: 'fa fa-reply')
        end.on(:click) do |event|
          event.prevent_default
          search_query&.delete(:filters)
          search
        end
      end

      def layout_padding
        'pt-0'
      end

      def placeholder
        # no placeholder for table
      end

      def set_filter_from_dashboard
        if search_query_filters_changed?
          redraw_datatable
        end
        mutate
      end

      def columns_changed?
        @columns_changed
      end

      def set_label_and_legend_translations(reload = false)
        # nothing
      end

      def filtered?
        search_query.dig(:filters)&.any?
      end

    end
  end
end
