# backtick_javascript: true

class Crm
  module Chart
    class Line < Base

      render { content }

      stack_mixin

      [
        :curve,
        :interpolate,
        :tension,
        :defined,
        :dash_style,
        :render_area,
        :xy_tips_on,
        :dot_radius,
        :render_data_points,
      ].each { |m| api_method(m) }

      [
        :plot_data,
        :legend_highlight,
        :legend_reset,
        :legendables,
      ].each { |m| alias_method(m) }

      def default_settings
        base = {
          dot_radius: 6,
          elastic_y: true,
          render_data_points: true,
          x_from_groups: true,
          round_from_groups: true,
          x_units_from_groups: true,
          elastic_x_from_groups: true,
          render_area: true,
          render_legend: false,
          legend_x: nil,
          legend_y: nil,
          x_axis_ticks: nil,
          y_axis_ticks: nil,
          xy_tips_on: true,
          pretransition: pretransition,
          brush_on: false,
        }
        if zoom_applicable?
          base.merge(mouse_zoomable: true, zoom_scale: [1, 50], zoom_out_restrict: true)
        end
      end

      def zoom_applicable?
        g = x_group
        return false unless g
        g.agg == 'date_histogram' || g.agg == 'histogram' || (g.agg == 'terms' && (g&.value_type == 'date' || g&.value_type == 'number'))
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

      def init
        @last_data_version = nil
        super
        self.compute_margins = true
        disable_sorting
      end

      def disable_sorting
        return unless @native
        `#{@native}.ordering(function(d) { return 0; })`
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

      def pretransition
        return unless zoom_applicable?
        Proc.new do |chart|
          attach_context_menu_listener(chart)
          zoom_pretransition(chart)
        end.to_n
      end

      def attach_context_menu_listener(chart)
        `
          chart.selectAll('circle.dot').on('contextmenu.get_key', function(e, d) {
            e.preventDefault();
            var key = d.data.key;
            #{set_current_key(`key`)};

          })
        `
      end
    end
  end
end

