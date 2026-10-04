# backtick_javascript: true

class Crm
  module Chart
    class Sunburst < Base

      render { content }

      color_mixin
      cap_mixin

      [
        :inner_radius,
        :radius,
        :cx,
        :cy,
        :min_angle_for_label,
        :empty_title,
        :external_labels,
      ].each { |m| api_method(m) }

      [
        :default_ring_sizes,
        :equal_ring_sizes,
        :relative_ring_sizes,
        :legendables,
        :legend_highlight,
        :legend_reset,
        :legend_toggle,
      ].each { |m| alias_method(m) }


      def default_settings
        return {
          cx: 0,
          cy: 0,
          width: 768,
          height: 480,
          empty_title: "Vide",
          min_angle_for_label: 0.5,
          slices_cap: 5,
          inner_radius: 0,
          external_labels: 0,
          legend: legend_highlight_selected,
          pretransition: pretransition,
        }
      end

      def pretransition
        Proc.new do |chart|
          `
            chart.selectAll('text.pie-slice').text(function(d) {
              return d.data.key + ' ' + dc.utils.printSingleValue((d.endAngle - d.startAngle) / (2*Math.PI) * 100) + '%';
            })
          `
        end.to_n
      end

      def legend_highlight_selected
        `dc.legend().highlightSelected(true)`
      end

    end
  end
end
