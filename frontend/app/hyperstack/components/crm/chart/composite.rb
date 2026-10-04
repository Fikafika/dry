class Crm
  module Chart
    class CompositeChart < Base
      render { content }

      coordinate_grid_mixin

      [
        :resizing,
        :use_right_axis_grid_lines,
        :child_options,
        :right_y_axis_label,
        :height,
        :width,
        :margins,
        :share_colors,
        :share_title,
        :right_y,
        :align_y_axes,
        :right_y_axis,
      ].each { |m| api_method(m) }

      [
        :rescale,
        :render_y_axis,
        :plot_data,
        :fade_deselected_area,
        :compose,
        :native_children,
        :x_axis_min,
        :x_axis_max,
        :legendables,
        :legend_highlight,
        :legend_reset,
        :legend_toggle,
        :y_axis_min,
        :y_axis_max,
      ].each { |m| alias_method(m) }

    end
  end
end
