# backtick_javascript: true

class Crm
  module Chart
    class Row < Base
      render { content }

      margin_mixin
      cap_mixin
      color_mixin

      [
        :x,
        :render_title_label,
        :x_axis,
        :fixed_bar_height,
        :gap,
        :elastic_x,
        :label_offset_x,
        :label_offset_y,
        :title_label_offset_x,
      ].each do |m|
        api_method(m)
      end


      def default_settings
        return {
          width: 768,
          height: 480,
          elastic_x_from_groups: true,
          fixed_bar_height: false,
          gap: 5,
          label_offset_x: 10,
          label_offset_y: 15,
          elastic_x: true,
          render_title_label: false,
          title_label_offset_x: 2,
          render_legend: false,
          legend_x: nil,
          legend_y: nil,
          x_axis_ticks: nil,
          pretransition: pretransition,
        }
      end

      attr_accessor :x_axis_ticks

      def init
        super
        disable_sorting
      end

      def disable_sorting
        return unless @native
        `#{@native}.ordering(function(d) { return 0; })`
      end

      def x_axis_ticks=(v)
        return unless @x_axis_ticks != v
        @x_axis_ticks = v
        a = v || `null`
        `#{@native}.xAxis().ticks(a)`
      end

      def attach_context_menu_listener(chart)
        `
          chart.selectAll('g.row').on('contextmenu.get_key', function(e, d) {
            e.preventDefault();
            var key = d.key;
            #{set_current_key(`key`)};

          })
        `
      end

      def axis_sort_buttons
        assign_sort_from_search_query?
        valid = %w[asc desc]
        current = other_params[:sort] ||= {}
        x = current['x']
        y = current['y']
        current['x'] = valid.include?(x) ? x : nil
        current['y'] = valid.include?(y) ? y : nil
        DIV(class: 'axis-sort-buttons position-absolute d-flex', style: { top: '2px', left:'2px', zIndex: 1}) do
          title = I18n.t('crm.chart.sort.sort_by_key')
          label = I18n.t("crm.chart.sort.axis.#{current['x'] || 'none'}")
          A(href: '#', class: "axis-sort-btn axis-sort-x btn btn-sm btn-outline-secondary", title: "#{title} : #{label}") do
            I(class: "fa fa-sort-amount-#{current['x'] || 'asc'}")
          end.on(:click) do |event|
            event.prevent_default
            event.stop_propagation
            apply_axis_sort('x')
          end
        end
        DIV(class: 'axis-sort-buttons position-absolute d-flex', style: {bottom: '2px', right: '2px', zIndex: 1}) do
          title = I18n.t('crm.chart.sort.sort_by_value')
          label = I18n.t("crm.chart.sort.axis.#{current['y'] || 'none'}")
          A(href: '#', class: "axis-sort-btn axis-sort-y btn btn-sm btn-outline-secondary", title: "#{title} : #{label}") do
            I(class: "fa fa-sort-amount-#{current['y'] || 'asc'}")
          end.on(:click) do |event|
            event.prevent_default
            event.stop_propagation
            apply_axis_sort('y')
          end
        end
      end

      def need_to_format_date?
        return true
      end


      def pagination_applicable?
        g = x_group
        return false unless g
        g.agg != 'date_histogram' && g.agg != 'histogram'
      end


      def pagination_buttons
        return unless pagination_applicable?
        A(href: '#', class: "btn btn-outline-secondary btn-sm position-absolute #{'disabled' unless show_drill_up_button?}",
          style: {top: '50%', left: 0, transform: 'translateY(-50%)', zIndex: 1}) do
          I(class: 'fas fa-chevron-up')
        end.on(:click) do |e|
          e.prevent_default
          next unless show_drill_up_button?
          do_drill_up
          registry.render_or_redraw
        end
        A(href: '#', class: "btn btn-outline-secondary btn-sm position-absolute #{'disabled' unless show_drill_down_button?}",
          style: {top: '50%', right: 0, transform: 'translateY(-50%)', zIndex: 1}) do
          I(class: 'fas fa-chevron-down')
        end.on(:click) do |e|
          e.prevent_default
          next unless show_drill_down_button?
          do_drill_down
          registry.render_or_redraw
        end
      end

      def pretransition
        Proc.new do |chart|
          attach_context_menu_listener(chart)
          `
            chart.selectAll('g.row').each(function(){
              var g = d3.select(this);
              var rect = g.select('rect');
              var text = g.select('text');

              var h = rect.attr('height') || 0;

              if (h > 0) {
                text.attr('y', h / 2);
              }
            })
          `
        end.to_n
      end

      def render_rotation_style
        return rotation_style("g.axis", other_params[:rotation_degree_x])
      end
    end
  end
end
