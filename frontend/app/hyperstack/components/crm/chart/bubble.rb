class Crm
  module Chart
    class Bubble < Base
      render { content }

      coordinate_grid_mixin
      bubble_mixin

      [
        :plot_data,
        :render_brush,
        :redraw_brush,
      ].each{|m| alias_method(m) }


    end
  end
end


