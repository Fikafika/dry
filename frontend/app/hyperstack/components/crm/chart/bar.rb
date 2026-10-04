# backtick_javascript: true

require 'components/crm/chart/base'

class Crm
  module Chart
    class Bar < Base

      render { content }

      def init
        @last_data_version = nil
        super
        disable_sorting
      end

      def disable_sorting
        return unless @native
        `#{@native}.ordering(function(d) { return 0; })`
      end

      def set_label_and_legend_translations(reload = false)
        @proc_for_translate_label = nil if reload
        super(reload)
        set_tick_format
      end

      def set_tick_format
        if proc_for_translate_label
          `#{@native}.xAxis().tickFormat(#{proc_for_translate_label})`
        end
      end

      def label_translation_proc(mapping)
        Proc.new do |l|
          next unless `l`
          l = `l.data` if `l.data`
          next mapping[`l.key`] if `l.key`
          next mapping[l] || l
        end
      end

      def set_legend_translations
        return unless `#{@native}.legend()`
        klass = other_params[:klass_name]&.safe_constantize
        if z_group
          z_keys = current_z_keys
          y_group_ids = current_y_group_ids
          mapping = klass&.attributes&.dig(z_group.attr, 'mapping_invert', I18n.locale) || {}
          `#{@native}.legend().legendText(#{proc_for_z_legend_text(klass, z_keys, mapping, y_group_ids)})`
        else
          legends = y_groups.map {|ygs| ygs.attr}.compact.presence || Array(x_group&.attr)
          `#{@native}.legend().legendText(#{proc_for_legend_text(klass, legends)})`
        end
      end

      def proc_for_legend_text(klass, legends)
        Proc.new do |d|
          index = `d.name`.to_i
          klass&.human_attribute_name(legends[index], I18n.locale) || index
        end
      end

      def proc_for_z_legend_text(klass, z_keys, mapping, y_group_ids = [])
        ygs = y_groups
        y_count = [y_group_ids.size, 1].max
        Proc.new do |d|
          index = `d.name`.to_i
          z_idx = index / y_count
          y_idx = index % y_count
          z_key = z_keys[z_idx]
          next unless z_key

          z_label = (mapping[z_key] || z_key).to_s
          if y_group_ids.any?
            yg = ygs[y_idx]
            y_label = yg ? klass&.human_attribute_name(yg.attr, I18n.locale).to_s : ''
            "#{z_label}: #{y_label}"
          else
            z_label
          end
        end
      end

      stack_mixin

      [
        :outer_padding,
        :center_bar,
        :bar_padding,
        :gap,
        :always_use_rounding,
      ].each { |m| api_method(m) }

      [
        :plot_data,
        :fade_deselected_area,
        :extend_Brush,
        :legend_highlight,
        :legend_reset,
      ].each { |m| alias_method(m) }


      def default_settings
        base = {
          width: 768,
          height: 480,
          center_bar: false,
          always_use_rounding: false,
          bar_padding: 2,
          outer_padding: 0.5,
          gap: 2,
          elastic_x_from_groups: true,
          elastic_y: true,
          render_horizontal_grid_lines: false,
          render_vertical_grid_lines: false,
          x_from_groups: true,
          round_from_groups: true,
          x_units_from_groups: true,
          margins_top: 0,
          margins_right: 0,
          margins_bottom: 0,
          margins_left: 0,
          render_legend: false,
          legend_x: nil,
          legend_y: nil,
          x_axis_ticks: nil,
          y_axis_ticks: nil,
          pretransition: pretransition,
          brush_on: false,
        }
        if zoom_applicable?
          base.merge(mouse_zoomable: true, zoom_scale: [1, 50], zoom_out_restrict: true)
        else
          base.merge(mouse_zoomable: false)
        end
      end

      def zoom_applicable?
        g = x_group
        return false unless g
        g.agg == 'auto_date_histogram' || g.agg == 'histogram'
      end

      def elastic_x_from_groups=(v)
        g = x_group
        return self.elastic_x = false if zoom_applicable?
        super
      end

      def x_domain_from_groups
        g = x_group
        return super unless zoom_applicable?

        data = registry.response.dig(:charts)&.detect{|c| c[:uuid] == other_params[:id]}&.[](:data) || []
        keys = data.map{|h| h['key'] || h[:key]}.compact

        return super if keys.empty?

        if g.value_type == 'date'
          [`new Date(#{keys.min})`, `new Date(#{keys.max})`]
        else
          [keys.min, keys.max]
        end
      end

      def pretransition
        return unless zoom_applicable?
        Proc.new do |chart|
          attach_context_menu_listener(chart)
          zoom_pretransition(chart)
        end.to_n
      end

      def pagination_applicable?
        g = x_group
        return false unless g
        g.agg != 'auto_date_histogram' && g.agg != 'histogram'
      end

      def pagination_buttons
        return unless pagination_applicable?
        A(href: '#', class: "btn btn-outline-secondary btn-sm position-absolute #{'disabled' unless show_drill_up_button?}",
          style: {top: '50%', left: 0, transform: 'translateY(-50%)', zIndex: 1}) do
          I(class: 'fas fa-chevron-left')
        end.on(:click) do |e|
          e.prevent_default
          next unless show_drill_up_button?
          do_drill_up
          registry.render_or_redraw
        end
        A(href: '#', class: "btn btn-outline-secondary btn-sm position-absolute #{'disabled' unless show_drill_down_button?}",
          style: {top: '50%', right: 0, transform: 'translateY(-50%)', zIndex: 1}) do
          I(class: 'fas fa-chevron-right')
        end.on(:click) do |e|
          e.prevent_default
          next unless show_drill_down_button?
          do_drill_down
          registry.render_or_redraw
        end
      end

      def attach_context_menu_listener(chart)
        `
          chart.selectAll('rect.bar').on('contextmenu.get_key', function(e, d) {
            e.preventDefault();
            var key = d.x;
            #{set_current_key(`key`)};
          })
        `
      end
    end
  end
end
