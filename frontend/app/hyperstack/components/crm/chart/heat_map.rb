class Crm
  module Chart
    class HeatMap < Base
      render { content }

      margin_mixin
      color_mixin


      [
        :cols_label,
        :rows_label,
        :rows,
        :row_ordering,
        :cols,
        :cols_ordering,
        :box_on_click,
        :x_axis_on_click,
        :y_axis_on_click,
        :x_border_radius,
        :y_border_radius,
      ].each { |m| api_method(m) }

      [
        :is_selected_node,
      ].each { |m| alias_method(m) }

    end
  end
end
