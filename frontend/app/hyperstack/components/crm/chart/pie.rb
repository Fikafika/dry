# backtick_javascript: true

class Crm
  module Chart
    class Pie < Base

      render { content }

      cap_mixin
      color_mixin

      [
        :slices_cap,
        :external_radius_padding,
        :inner_radius,
        :radius,
        :cx,
        :cy,
        :min_angle_for_label,
        :empty_title,
        :external_labels,
        :draw_paths,
      ].each { |m| api_method(m) }

      [
        :legendables,
        :legend_highlight,
        :legend_reset,
        :legend_toggle,
      ].each { |m| alias_method(m) }


      def default_settings
        return {
          cx: 0,
          cy: 0,
          # width: 768,
          # height: 480,
          draw_paths: false,
          empty_title: I18n.t('shared.empty'),
          min_angle_for_label: 0.5,
          inner_radius: 0,
          external_radius_padding: 0,
          external_labels: 0,
          pretransition: pretransition,
          render_legend: true,
          legend_x: nil,
          legend_y: nil,
          use_view_box_resizing: true,
        }
      end

      def pretransition
        if proc_for_translate_label
          Proc.new do |chart|
            `
              chart.selectAll('text.pie-slice').text(function(d) {
                var k = #{proc_for_translate_label}(d.data)
                return k + ' ' + dc.utils.printSingleValue((d.endAngle - d.startAngle) / (2*Math.PI) * 100) + '%';
              })
              #{attach_context_menu_listener(chart)}
            `
          end.to_n
        else
          Proc.new do |chart|
            `
              chart.selectAll('text.pie-slice').text(function(d) {
                return d.data.key + ' ' + dc.utils.printSingleValue((d.endAngle - d.startAngle) / (2*Math.PI) * 100) + '%';
              })
              #{attach_context_menu_listener(chart)}
            `
          end.to_n
        end
      end

      def attach_context_menu_listener(chart)
        `
          chart.selectAll('g.pie-slice').on('contextmenu.get_key', function(e, d) {
            e.preventDefault();
            var key = d.data.key;
            #{set_current_key(`key`)};
          })
        `
      end

      def init_dc_chart_data_with_others
        # currently disabled
        wrapper.controls_use_visibility = true
        wrapper.data = data_for_group_with_other_at_the_end
      end

      def need_to_format_date?
        return true
      end
    end

    def data_for_group_with_other_at_the_end # TODO
      `var other_at_end = function(group) {
          var all = group.all();
          var rest = [];
          var items = [];
          for(i = 0; i < all.length; i++) {
            if (all[i].key == '_others_') {
              rest.push(all[i])
            } else {
              items.push(all[i])
            }
          }
          items = dc_chart._computeOrderedGroups(items); // sort by baseMixin.ordering

          if (dc_chart.cap()) {
            if (dc_chart.takeFront()) {
              rest = rest.concat(items.slice(dc_chart.cap()));
              items = items.slice(0, dc_chart.cap());
            } else {
              var start = Math.max(0, items.length - dc_chart.cap());
              rest = rest.concat(items.slice(0, start));
              items = items.slice(start);
            }
          }
          items.sort((a,b) => d3.ascending(a.key, b.key));
          if (dc_chart.othersGrouper()) {
            return dc_chart.othersGrouper()(items, rest);
          }


          return items;
        }
      `
    end

  end
end
