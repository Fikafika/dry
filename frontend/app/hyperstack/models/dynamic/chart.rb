if RUBY_ENGINE != 'opal'
  require 'boolean'
end

module Dynamic

  module Chart

    class Base < Dynamic::Base
      define_api_path # /api/d/uneek/r__charts


      # TODO schema should provide table definitions

      attribute :klass_name, type: String
      attribute :layouts, type: Hash, default: {}

      # base mixin ------------------------------

      attribute :height, type: Float
      attribute :width, type: Float
      attribute :min_height, type: Float
      attribute :min_width, type: Float
      attribute :use_view_box_resizing, type: Boolean, default: false
      # :dimension
      # :data
      # :group
      # :ordering
      # :anchor
      # :svg_description
      # t.boolean :keyboard_accessible, type: Boolean, default: false
      # :filter_printer
      attribute :transition_duration, type: Integer, default: 750
      attribute :transition_delay, type: Integer, default: 0
      # :commit_handler
      # :has_filter_handler
      # :remove_filter_handler
      # :add_filter_handler
      # :filter
      # :filterHandler
      attribute :label, type: String
      attribute :render_label, type: Boolean, default: false
      attribute :title, type: String
      attribute :render_title, type: Boolean, default: true
      # :chart_group
      # :legend
      attribute :render_legend, type: Boolean, default: false
      attribute :legend_x, type: Float
      attribute :legend_y, type: Float

      # coordinate mixin --------------------------

      # :resizing
      # :range_chart
      # :zoom_scale
      # :zoom_out_restrict
      # :g
      # :mouse_zoomable
      # :chart_body_g
      # :x
      # :x_units
      # :x_axis
      attribute :elastic_x, type: Boolean
      # :x_axis_padding
      # :x_axis_padding_unit
      attribute :use_right_y_axis, type: Boolean, default: false
      attribute :use_top_x_axis, type: Boolean, default: false
      attribute :x_axis_label, type: String
      attribute :x_axis_ticks, type: Integer
      # :y
      # :y_axis
      attribute :y_axis_label, type: String
      attribute :y_axis_ticks, type: Integer
      attribute :elastic_y, type: Boolean

      attribute :render_horizontal_grid_lines, type: Boolean
      attribute :render_vertical_grid_lines, type: Boolean
      # :y_axis_padding
      # :round
      # :brush
      # :clip_padding
      # :focus_chart
      # :brush_on
      # :parent_brush_on

      # color mixin ------------------------------

      # :calculate_color_domain
      attribute :colors, type: Array
      attribute :ordinal_colors, type: Array
      # :color_domain
      # :color_calculator
      attribute :linear_colors, type: Array

      # stack mixin ------------------------------

      # :stack
      # :hidable_stacks
      # :stack_layout
      # :evade_domain_filter

      # margin mixin -----------------------------

      attribute :margins_top, type: Float, default: 10
      attribute :margins_right, type: Float, default: 50
      attribute :margins_bottom, type: Float, default: 30
      attribute :margins_left, type: Float, default: 30

      #  cap mixin -------------------------------

      attribute :cap, type: Integer
      attribute :take_front, type: Boolean
      attribute :others_label, type: String
      # :others_grouper

      # bubble mixin -----------------------------

      # :r
      attribute :elastic_radius, type: Boolean, default: false
      # :radius_value_accessor
      # :sort_bubble_size
      attribute :min_radius, type: Float, default: 10
      attribute :min_radius_with_label, type: Float, default: 10
      attribute :max_bubble_relative_size, type: Float, default: 0.3
      attribute :exclude_elastic_zero, type: Boolean, default: true

      # boxplot mixin -----------------------------

      # :box_padding
      attribute :outer_padding, type: Float, default: 0.5
      # :box_width
      # :tick_format
      # :y_range_padding
      # :render_data_points
      # :data_opacity
      # :data_width_portion
      # :show_outliers
      # :bold_outlier

      # composite mixin ---------------------------

      # :resizing
      # :use_right_axis_grid_lines
      # :child_options
      # :right_y_axis_label
      # :height
      # :width
      # :margins
      # :share_colors
      # :share_title
      # :right_y
      # :align_y_axes
      # :right_y_axis

      # bar ---------------------------------------

      attribute :center_bar, type: Boolean
      attribute :bar_padding, type: Float, default: 0
      attribute :gap, type: Float, default: 2
      attribute :always_use_rounding, type: Boolean, default: false

      #  data count --------------------------------

      # :html
      # :format_number
      # :crossfilter
      # :group_all

      # data grid ----------------------------------

      # :section
      # :begin_slice
      # :end_slice
      # :size
      # :html
      # :html_section
      # :html_group
      # :sort_by
      # :order

      # data table ----------------------------------

      # :section
      # :size
      # :begin_slice
      # :end_slice
      # :columns
      # :sort_by
      # :order
      # :show_sections
      # :show_groups

      # geo choropleth --------------------------------

      # :overlay_geo_json
      # :projection

      # heat map ---------------------------------------

      attribute :cols_label, type: String
      attribute :rows_label, type: String
      # :rows
      # :row_ordering
      # :cols
      # :cols_ordering
      # :box_on_click
      # :x_axis_on_click
      # :y_axis_on_click
      # :x_border_radius
      # :y_border_radius

      # line ---------------------------------------------

      # :curve
      # :interpolate
      # :tension
      # :defined
      # :dash_style
      # :render_area
      # :xy_tips_on
      # :dot_radius
      # :render_data_points

      # number display -------------------------------------

      # :html
      # :format_number
      # :aria_live_region

      # pie ------------------------------------------------

      attribute :slices_cap, type: Integer
      attribute :external_radius_padding, type: Float
      attribute :inner_radius, type: Float
      attribute :radius, type: Float
      attribute :cx, type: Float
      attribute :cy, type: Float
      attribute :min_angle_for_label, type: Float, default: 0.5
      attribute :empty_title, type: String
      attribute :external_labels, type: Float
      # :draw_paths

      # row -------------------------------------------------

      #rotation
      attribute :rotation_degree_x, type: Float
      attribute :rotation_degree_y, type: Float
      # :x
      attribute :render_title_label, type: Boolean, default: false
      # :x_axis
      # :fixed_bar_height
      # :gap
      # :elastic_x
      # :label_offset_x
      # :label_offset_y
      # :title_label_offset_x

      # scatter plot -----------------------------------------

      # :filter
      # :use_canvas
      # :canvas
      # :existence_accessor
      # :symbol
      # :custom_symbol
      # :symbol_size
      # :highlighted_size
      # :excluded_size
      # :excluded_color
      # :excluded_opacity
      # :empty_size
      # :hidden_size
      # :empty_color
      # :empty_opacity
      # :nonempty_opacity

      # series -------------------------------------------------

      # :chart
      # :series_accessor
      # :series_sort
      # :value_sort

      translates [:human_name, :title, :label, :cols_label, :rows_label, :empty_title, :x_axis_label, :y_axis_label]
      globalize_accessors

      def initialize(json)
        super
        self.scope = { include: {translations: 1}}
      end

      class << self

        def subclasses
          [
            Pie,
            Row,
            Bar,
            Sunburst,
            Line,
            Bubble,
            ScatterPlot,
            BoxPlot,
            HeatMap,
            Composite,
            Series,
            GeoChoropleth,
            DataCount,
            DataGrid,
            DataTable,
            Table,
            BubbleOverlay,
            NumberDisplay,
          ]
        end

        def with_includes_for_load
          includes(includes_for_load)
        end

        def includes_for_load
          {
            translations: 1,
            groups: {include: {translations: 1, ranges: 1}},
            x_groups: {include: {translations: 1, ranges: 1}},
            y_groups: {include: {translations: 1, ranges: 1}},
            z_groups: {include: {translations: 1, ranges: 1}},
          }
        end
      end

      def create
        r = super
        r.then do
          dashboard&.reload
        end
        r
      end

      def update(attributes, options = {reload_dashboard: true}, &block)
        r = super(attributes, &block)
        r.then do
          dashboard&.reload
        end if options[:reload_dashboard]
        r
      end

      def destroy
        r = super
        r.then do
          self.dashboard&.reload
        end
        r
      end

    end

    class Pie < Base; end
    class Row < Base; end
    class Bar < Base; end
    class Sunburst < Base; end
    class Line < Base; end
    class Bubble < Base; end
    class ScatterPlot < Base; end
    class BoxPlot < Base; end
    class HeatMap < Base; end
    class Composite < Base; end
    class Series < Base; end
    class GeoChoropleth < Base; end
    class DataCount < Base; end
    class DataGrid < Base; end
    class DataTable < Base; end
    class Table < Base; end
    class BubbleOverlay < Base; end
    class NumberDisplay < Base; end

    class Group < Dynamic::Base
      define_api_path # /api/d/uneek/r__chart__groups
      include ::HyperResource::EnumString

      class << self

        def with_includes_for_load
          includes(translations: 1, ranges: 1)
        end

      end

      translates :human_name
      globalize_accessors

      enum source: [
        :attr,
        :script,
      ], _prefix: true

      attribute :attr, type: String
      attribute :script, type: String

      enum value_type: [
        :string,
        :date,
        :boolean,
        :number,
      ], _prefix: true

      enum agg: {
        terms: 0,
        date_histogram: 1,
        range: 2,
        date_range: 3,
        histogram: 4,
        top_values: 5,
        filters: 6,
        avg: 7,
        median: 8,
        count: 9,
        sum: 10,
        min: 11,
        max: 12,
        couter_rate: 13,
        cumulative_sum: 14,
        differences: 15,
        last_value: 16,
        percentile: 17,
        uniq_count: 18,
        moving_average: 19,
        cardinality: 20,
        median_absolute_deviation: 21,
        matrix_stats: 22,
        percentile_ranks: 23,
        percentiles: 24,
        string_stats: 25,
        boxplot: 26,
        extended_stats: 27,
        geo_bounds: 28,
        geo_centroid: 29,
        geo_line: 30,
        significant_terms: 31,
      }, _prefix: true

      enum axis: [
        :x,
        :y,
        :z,
      ], _prefix: true

      attribute :min, type: String
      attribute :max, type: String

      attribute :position, type: Integer

      class Range < Dynamic::Base
        define_api_path # /api/d/uneek/r__chart_group_ranges

        attribute :from, type: String
        attribute :to, type: String
      end

    end

  end

end
