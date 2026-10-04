class Crm
  module Chart
    class ScatterPlot < Base
      render { content }

      coordinate_grid_mixin

      [
        :filter,
        :use_canvas,
        :canvas ,
        :existence_accessor,
        :symbol,
        :custom_symbol,
        :symbol_size,
        :highlighted_size,
        :excluded_size,
        :excluded_color,
        :excluded_opacity,
        :empty_size ,
        :hidden_size,
        :empty_color,
        :empty_opacity,
        :nonempty_opacity,
      ].each { |m| api_method(m) }

      [
        :reset_svg,
        :context,
        :plot_data,
        :legendables,
        :legend_highlight,
        :legend_reset,
        :create_brush_handle_paths,
        :extend_brush,
        :brush_is_empty,
        :redraw_Brush,
      ].each { |m| alias_method(m) }

    end
  end
end
