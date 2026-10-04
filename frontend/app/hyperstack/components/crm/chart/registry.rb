# backtick_javascript: true

class Crm
  module Chart
    module Registry

      def with_delay
        @delay&.abort
        @delay = after!(0.1) do
          yield
        end
        @delay.start
      end

      def response
        @response ||= {}
      end

      def response=(v)
        @response = v
      end

      def charts
        @charts ||= {}
      end

      def chart_records
        # redefined in included
      end

      def load_charts_data(force: false)
        return unless chart_records&.any? && search_query

        table = charts.values.detect{|c| c.is_a?(::Crm::Chart::Table) }

        if table
          table.load_charts_data(reload: force) do
            yield
          end
        else
          data = {}
          data[:time_zone] = `Intl.DateTimeFormat().resolvedOptions().timeZone`
          data[:search_query] = search_query.dump
          data[:dashboard_id] = dashboard_id
          @promise ||= HyperResource::HTTP.post("#{klass.api_path}/dashboard", payload: data).then do |r|
            @promise = nil
            @response = r.json
            yield
          end
        end
      end

      def render_all?
        charts.any? && !@rendered
      end

      def render_all
        @rendered = true
        `dc.renderAll()`
      end

      def redraw_all
        `dc.redrawAll()`
      end

      def resize_all
        return unless @rendered
        without_animations do
          `dc.redrawAll()`
        end
      end

      def without_animations
        previous_animations = {}
        charts.each do |c_id, c|
          next unless c.respond_to?(:transition_duration=)
          duration = Native.call(c.instance_variable_get(:@native), :transitionDuration)
          previous_animations[c_id] = duration
          c.transition_duration = 0
        end
        yield
        charts.each do |c_id, c|
          next unless c.respond_to?(:transition_duration=)
          c.transition_duration = previous_animations[c_id]
        end
      end

      def register(uuid, chart)
        charts[uuid] = chart
      end

      def deregister(uuid)
        return unless charts[uuid]
        c = charts[uuid].to_n
        `if (dc.chartRegistry.has(c)) dc.chartRegistry.deregister(c)`
        charts.delete(uuid)
        @rendered = false if charts.empty?
      end

      def deregister_all_charts
        `dc.deregisterAllCharts()`
        @charts = {}
        @rendered = false
      end

      def remove_all_charts
        charts.values.each do |c|
          c.hide_reset_filter_btn
          c.hide_reset_sort_btn
          c.reset_svg
          c.jq_node.find('svg').remove_attr('width')
          c.jq_node.find('svg').remove_attr('height')
        end
        deregister_all_charts
      end

      def after_render_search
        if @prevent_after_render_search
          @prevent_after_render_search = false
          return
        end

        return if request.params[:action] == 'last_search'

        if chart_records.any?
          if !@rendered || search_query_params_changed?
            render_or_redraw
            store_previous_states
          end
        end
      end

      def render_or_redraw(force: false)
        if render_all?
          load_charts_data(force: force) do
            render_all
          end
        else
          load_charts_data(force: force) do
            redraw_all
          end
        end
      end

      def reset_tables_selection
        charts.values.select { |c| c.is_a?(Crm::Chart::Table) }.each(&:reset_selection)
      end

      def reload_data
        tables = charts.values.select { |c| c.is_a?(Crm::Chart::Table) }
        if tables.any?
          last_index = tables.size - 1
          tables.each_with_index do |table, index|
            if index == last_index
              table.load_charts_data(reload: true) { redraw_all }
            else
              table.load_charts_data(reload: true)
            end
          end
        else
          load_charts_data { redraw_all }
        end
      end

    end
  end
end
