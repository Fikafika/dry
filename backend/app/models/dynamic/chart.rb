module Dynamic
  module Chart
    class Base < ActiveRecord::Base
      self.abstract_class = true
      self.store_full_sti_class = false

      include Dynamic::Mount

      def url_id
        "chart-#{self.id.to_s[-8..-1]}"
      end

      define_table do |t|
        t.belongs_to :dashboard, type: :uuid
        t.belongs_to :user, type: :uuid

        t.string :human_name, translate: true
        t.boolean :render_human_name, default: true

        t.text :klass_name
        t.json :layouts, default: {}

        # base mixin ------------------------------

        t.float :height
        t.float :width
        t.float :min_height
        t.float :min_width
        t.boolean :use_view_box_resizing, default: false
        # :dimension
        # :data
        # :group
        # :ordering
        # :anchor
        # :svg_description
        # t.boolean :keyboard_accessible, default: false
        # :filter_printer
        t.integer :transition_duration, default: 750
        t.integer :transition_delay, default: 0
        # :commit_handler
        # :has_filter_handler
        # :remove_filter_handler
        # :add_filter_handler
        # :filter
        # :filterHandler
        t.string :label, translate: true
        t.boolean :render_label
        t.string :title, translate: true
        t.boolean :render_title, default: true
        # :chart_group
        # :legend
        t.boolean :render_legend
        t.float :legend_x
        t.float :legend_y

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
        t.boolean :elastic_x
        # :x_axis_padding
        # :x_axis_paddingUnit
        t.boolean :use_right_y_axis, default: false
        t.boolean :use_top_x_axis, default: false
        t.string :x_axis_label, translate: true
        t.integer :x_axis_ticks
        # :y
        # :y_axis
        t.boolean :elastic_y
        t.boolean :render_horizontal_grid_lines
        t.boolean :render_vertical_grid_lines
        t.string :y_axis_label, translate: true
        t.integer :y_axis_ticks
        # :y_axis_padding
        # :round
        # :brush
        # :clip_padding
        # :focus_chart
        # :brush_on
        # :parent_brush_on

        # color mixin ------------------------------

        # :calculate_color_domain
        t.json :colors
        t.json :ordinal_colors
        # :color_domain
        # :color_calculator
        t.json :linear_colors

        # stack mixin ------------------------------

        # :stack
        # :hidable_stacks
        # :stack_layout
        # :evade_domain_filter

        # margin mixin -----------------------------

        t.float :margins_top, default: 10
        t.float :margins_right, default: 50
        t.float :margins_bottom, default: 30
        t.float :margins_left, default: 30

        #  cap mixin -------------------------------

        t.integer :cap
        t.boolean :take_front
        t.string :others_label, translate: true
        # :others_grouper

        # bubble mixin -----------------------------

        # :r
        t.boolean :elastic_radius, default: false
        # :radius_value_accessor
        # :sort_bubble_size
        t.float :min_radius, default: 10
        t.float :min_radius_with_label, default: 10
        t.float :max_bubble_relative_size, default: 0.3
        t.boolean :exclude_elastic_zero, default: true

        # boxplot mixin -----------------------------

        # :box_padding
        t.float :outer_padding, default: 0.5
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

        # t.float :outer_padding, default: 0.5
        t.boolean :center_bar
        t.float :bar_padding, default: 0
        t.float :gap, default: 2
        t.boolean :always_use_rounding, default: false

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

        t.string :cols_label, translate: true
        t.string :rows_label, translate: true
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
        t.boolean :render_area
        # :xy_tips_on
        # :dot_radius
        # :render_data_points

        # number display -------------------------------------

        # :html
        # :format_number
        # :aria_live_region

        # pie ------------------------------------------------

        t.integer :slices_cap
        t.float :external_radius_padding
        t.float :inner_radius
        t.float :radius
        t.float :cx
        t.float :cy
        t.float :min_angle_for_label, default: 0.5
        t.string :empty_title, translate: true
        t.float :external_labels
        # :draw_paths

        # row -------------------------------------------------

        #rotation
        t.float :rotation_degree_x
        t.float :rotation_degree_y
        # :x
        t.boolean :render_title_label, default: false
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

        # table --------------------------------------------------

        t.json :columns
        t.string :locked_column
        t.string :locked_column_right
        t.json :column_widths

        t.text :type
      end

      after_mount do
        belongs_to :dashboard, class_name: 'Dashboard', inverse_of: :charts, touch: true
        belongs_to :user, class_name: 'User', comes_from: [:dashboard], optional: true
        has_many :groups, class_name: 'Group', inverse_of: :chart, foreign_key: 'chart_id', dependent: :destroy
        has_many :x_groups, -> { where(axis: 'x') }, class_name: 'Group', inverse_of: :chart, foreign_key: 'chart_id'
        has_many :y_groups, -> { where(axis: 'y') }, class_name: 'Group', inverse_of: :chart, foreign_key: 'chart_id'
        has_many :z_groups, -> { where(axis: 'z') }, class_name: 'Group', inverse_of: :chart, foreign_key: 'chart_id'
        accepts_nested_attributes_for :groups, :x_groups, :y_groups, :z_groups, allow_destroy: true

        Dynamic::Chart::Base.sub_klasses.each do |k|
          self.module_parent.const_set(k.name.demodulize, Class.new(self))
        end
      end

      def self.sub_klasses
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
          BubbleOverlay,
          NumberDisplay,
          Table,
        ]
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
    class BubbleOverlay < Base; end
    class NumberDisplay < Base; end
    class Table < Base; end

    class Group < ActiveRecord::Base
      self.table_name = 'chart_groups'

      include Dynamic::Mount

      define_table do |t|
        t.string :human_name, translate: true
        t.integer :source
        t.string :attr
        t.integer :value_type
        t.integer :agg
        t.text :script
        t.integer :axis
        t.integer :min_doc_count
        t.integer :size
        t.boolean :show_others
        t.boolean :show_missing
        t.string :calendar_interval
        t.integer :interval
        t.integer :position, default: 0
        t.string :min
        t.string :max
        t.belongs_to :chart, type: :uuid
        t.belongs_to :user, type: :uuid
      end

      after_mount do
        belongs_to :chart, class_name: 'Chart::Base', inverse_of: :groups, touch: true
        belongs_to :user, class_name: 'User', comes_from: [:chart], optional: true
        has_many :ranges, class_name: 'Range', inverse_of: :group, foreign_key: 'group_id', dependent: :destroy
        accepts_nested_attributes_for :ranges, allow_destroy: true

        safe_enum :source, {
          attr: 0,
          script: 1,
        }

        validates_presence_of :source

        safe_enum :value_type, {
          string: 0,
          date: 1,
          boolean: 2,
          number: 3,
        }

        validates_presence_of :attr, if: Proc.new { |g| g.source == 'attr' }
        validates_presence_of :script, if: Proc.new { |g| g.source == 'script' }
        validates_presence_of :value_type

        safe_enum :agg, {
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
          auto_date_histogram: 32,
        }

        validates_presence_of :agg

        safe_enum :axis, {
          x: 0,
          y: 1,
          z: 2,
        }

      end

      class Range < ActiveRecord::Base
        self.table_name = 'chart_group_ranges'

        include Dynamic::Mount

        define_table do |t|
          t.string :from
          t.string :to
          t.belongs_to :group, type: :uuid
          t.belongs_to :user, type: :uuid
        end

        after_mount do
          belongs_to :group, class_name: 'Chart::Group', inverse_of: :ranges, touch: true
          belongs_to :user, class_name: 'User', comes_from: [:group], optional: true
        end
      end
    end
  end
end
