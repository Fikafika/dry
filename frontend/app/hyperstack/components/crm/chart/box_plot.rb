class Crm
  module Chart
    class BoxPlot < Base
      render { content }

      coordinate_grid_mixin

      [
        :box_padding,
        :outer_padding,
        :box_width,
        :tick_format,
        :y_range_padding,
        :render_data_points,
        :data_opacity,
        :data_width_portion,
        :show_outliers,
        :bold_outlier,
      ].each { |m| api_method(m) }

      [
        :plot_data,
        :fade_deselected_area,
        :is_selected_node,
        :y_axis_min,
        :y_axis_max,
      ].each { |m| alias_method(m) }

    end
  end
end
