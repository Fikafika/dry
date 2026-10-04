class Crm
  module Chart
    class Settings < ::Crm::Base

      collect_other_params_as :other_params

      render() { content }

      def content
        observe record
        if (record&.new_record? || record&.loaded?) && klass
          @was_new_record = record.new_record?
          Sheet::Toolbar(side: 'right', record: record)
          DIV(class: 'container-fluid flex-column d-flex' ,style: { height: '95vh' }) do
            Form(record: record, class: 'mt-2 d-flex flex-column flex-grow-1') do
              Form::Element::Layout::Page(label: I18n.t('crm.chart.settings.graph_choice'), icon: "chart-simple", initialize_hidden_element: true) do
                H3(class: "mb-3") do
                  I18n.t('crm.chart.settings.graph_choice')
                end
                Form::Element::Attribute::String(attribute_name: 'klass_name', editor: 'hidden')
                Form::Element::Attribute::String(attribute_name: 'dashboard_id', editor: 'hidden')

                possible_values = chart_klasses.map do |subklass|
                  {
                    value: subklass.name.demodulize,
                    label: subklass.model_name.human,
                    you: subklass.name.demodulize,
                    icon: subklass.icon,
                  }
                end
                Form::Element::Attribute::Enum(attribute_name: 'type', editor: 'radio_card', possible_values: possible_values)
              end

              Form::Element::Layout::Page(label: I18n.t('crm.chart.settings.data'), icon: "database", initialize_hidden_element: true) do
                H3(class: "mb-3") do
                  I18n.t('crm.chart.settings.data')
                end
                Form::Element::Layout::Condition(type:  ['Table']) do
                  Form::Element::Attribute::Columns(attribute_name: 'columns', default_value: klass&.options_for_indexed_json.try(:[], 'only'), show_select_all: true)
                end

                Form::Element::Layout::Condition(type: [nil, 'Pie', 'Sunburst', 'DataCount', 'BoxPlot']) do
                  build_x_axis
                end

                Form::Element::Layout::Condition(type: ['NumberDisplay']) do
                  build_x_axis_one_value
                end
                Form::Element::Layout::Condition(type: ['Line', 'Bubble', 'Bar', 'Row']) do

                  H5(class: "mb-3") do
                    I18n.t('crm.chart.settings.x_axis')
                  end

                  Form::Element::Layout::Condition(type: ['Bar']) do
                    build_x_axis(add_histogram: true)
                  end

                  Form::Element::Layout::Condition(type: ['Row']) do
                    build_x_axis
                  end

                  Form::Element::Layout::Condition(type: ['Line', 'Bubble']) do
                    Form::Element::Association::HasMany(
                      attribute_name: 'x_groups',
                      mode: 'nested_form',
                      min: 1,
                      show_label: false,
                    ) do
                      Form::Element::Attribute::Enum(attribute_name: 'axis', editor: 'hidden', default_value: 'x')

                      attr_or_script

                      Form::Element::Layout::Condition(value_type: ['string']) do
                        Form::Element::Attribute::Enum(attribute_name: 'agg', possible_values: possible_aggs(['terms', 'significant_terms']), default_value: 'terms', requirement: 'mandatory', accept_empty_value: false)
                      end
                      Form::Element::Layout::Condition(value_type: ['number']) do
                        Form::Element::Attribute::Enum(attribute_name: 'agg', possible_values: possible_aggs(['terms', 'histogram', 'range']), default_value: 'terms', requirement: 'mandatory', accept_empty_value: false)
                        Form::Element::Attribute::String(attribute_name: 'min')
                        Form::Element::Attribute::String(attribute_name: 'max')
                      end
                      Form::Element::Layout::Condition(value_type: ['boolean']) do
                        Form::Element::Attribute::Enum(attribute_name: 'agg', possible_values: possible_aggs(['terms']), default_value: 'terms', requirement: 'mandatory', accept_empty_value: false)
                      end
                      Form::Element::Layout::Condition(value_type: ['date']) do
                        Form::Element::Attribute::Enum(attribute_name: 'agg', possible_values: possible_aggs(['date_histogram', 'date_range', 'terms']), default_value: 'date_histogram', requirement: 'mandatory', accept_empty_value: false)
                        Form::Element::Attribute::DateTime(attribute_name: 'min')
                        Form::Element::Attribute::DateTime(attribute_name: 'max')
                      end

                      Form::Element::Layout::Condition(agg: ['date_histogram']) do
                        Form::Element::Attribute::Enum(
                          attribute_name: 'calendar_interval',
                          possible_values: calendar_interval_possible_values(['1y', '1M', '1d', '1h', '1m', '1s', '1ms']),
                          default_value: '1d',
                          accept_empty_value: false,
                        )
                      end

                      Form::Element::Layout::Condition(value_type: ['string']) do
                        Form::Element::Attribute::Boolean(attribute_name: 'show_missing', default_value: false)
                      end

                      Form::Element::Layout::Condition(agg: ['range', 'date_range']) do
                        Form::Element::Association::HasMany(
                          attribute_name: 'ranges',
                          mode: 'nested_form',
                        ) do
                          Form::Element::Attribute::String(attribute_name: 'from')
                          Form::Element::Attribute::String(attribute_name: 'to')
                        end
                        Form::Element::Control::AddButton(attribute_name: 'ranges')
                      end
                    end
                  end

                  H5(class: "mb-3") do
                    I18n.t('crm.chart.settings.y_axis')
                  end
                  Form::Element::Layout::Condition(type: ['Line', 'Bubble', 'Bar']) do
                    build_y_axis
                    Form::Element::Control::AddButton(attribute_name: 'y_groups')
                  end

                  Form::Element::Layout::Condition(type: ['Row']) do
                    build_y_axis(max: 1)
                    Form::Element::Control::AddButton(attribute_name: 'y_groups')
                  end

                  Form::Element::Layout::Condition(type: ['Bar', 'Line']) do
                    H5(class: "mb-3") do
                      I18n.t('crm.chart.settings.z_axis')
                    end
                    build_z_axis
                    Form::Element::Control::AddButton(attribute_name: 'z_groups')
                  end
                end
              end

              Form::Element::Layout::Page(label: I18n.t('crm.chart.settings.legends'), icon: "list", initialize_hidden_element: true) do
                H3(class: "mb-3") do
                  I18n.t('crm.chart.settings.legends')
                end

                Form::Element::Attribute::Boolean(attribute_name: 'render_human_name', default_value: true)
                Form::Element::Layout::Condition(render_human_name: true) do
                  default_human_name = I18n.available_locales.each_with_object({}) do |locale, hash|
                    hash[locale] = record.send("human_name_#{locale}")
                  end

                  first_group = record.x_groups.first
                  unless first_group.nil?
                    I18n.available_locales.each do |locale|
                      attr_human_name = klass.human_attribute_name(first_group.attr, locale: locale)

                      default_human_name[locale] = attr_human_name if attr_human_name.blank?
                    end
                  end
                  if default_human_name.values.any?{|v| v.present?}
                    Form::Element::Attribute::TranslatableString(attribute_name: 'human_name', default_value: default_human_name)
                  end
                end

                all_types_except_table = [nil] + Dynamic::Chart::Base.subclasses.map{|n| n.name.demodulize} - ['Table']
                Form::Element::Layout::Condition(type: all_types_except_table) do

                  Form::Element::Attribute::Boolean(attribute_name: 'render_legend')
                  Form::Element::Layout::Condition(render_legend: true) do
                    Form::Element::Attribute::Float(attribute_name: 'legend_x')
                    Form::Element::Attribute::Float(attribute_name: 'legend_y')
                  end

                  Form::Element::Attribute::Boolean(attribute_name: 'render_title')
                  #Form::Element::Layout::Condition(render_title: true) do
                  #  Form::Element::Attribute::TranslatableString(attribute_name: 'title') # tooltip
                  #end

                  Form::Element::Attribute::Boolean(attribute_name: 'render_label')
                  #Form::Element::Layout::Condition(render_label: true) do
                  #  Form::Element::Attribute::TranslatableString(attribute_name: 'label')
                  #end

                  Form::Element::Layout::Condition(type:  ['Bar', 'Line']) do
                    Form::Element::Attribute::Boolean(attribute_name: 'render_horizontal_grid_lines')
                    Form::Element::Attribute::Boolean(attribute_name: 'render_vertical_grid_lines')
                  end

                  Form::Element::Layout::Condition(type:  ['Bar', 'Line', 'Row']) do
                    Form::Element::Attribute::Integer(attribute_name: 'x_axis_ticks')
                  end

                  Form::Element::Layout::Condition(type:  ['Bar', 'Line']) do
                    Form::Element::Attribute::Integer(attribute_name: 'y_axis_ticks')
                  end
                end
              end

              Form::Element::Layout::Page(label: I18n.t('crm.chart.settings.size'), icon: "up-right-and-down-left-from-center", initialize_hidden_element: true) do
                H3(class: "mb-3") do
                  I18n.t('crm.chart.settings.size')
                end

                Form::Element::Attribute::Float(attribute_name: 'width')
                Form::Element::Attribute::Float(attribute_name: 'height')

                Form::Element::Attribute::Float(attribute_name: 'min_width')
                Form::Element::Attribute::Float(attribute_name: 'min_height')

                Form::Element::Attribute::Float(attribute_name: 'margins_top')
                Form::Element::Attribute::Float(attribute_name: 'margins_right')
                Form::Element::Attribute::Float(attribute_name: 'margins_bottom')
                Form::Element::Attribute::Float(attribute_name: 'margins_left')

                Form::Element::Layout::Condition(type:  ['Bar', 'Line']) do
                  Form::Element::Attribute::Float(attribute_name: 'rotation_degree_x')
                  Form::Element::Attribute::Float(attribute_name: 'rotation_degree_y')
                end
                Form::Element::Layout::Condition(type: ['Row']) do
                  Form::Element::Attribute::Float(attribute_name: 'rotation_degree_x')
                end
                #Form::Element::Attribute::Boolean(attribute_name: 'use_view_box_resizing')

                Form::Element::Layout::Condition(type:  ['Bar', 'Row']) do
                  Form::Element::Attribute::Float(attribute_name: 'gap')
                end

                Form::Element::Layout::Condition(type:  ['Pie', 'Sunburst']) do
                  Form::Element::Attribute::Float(attribute_name: 'inner_radius')
                end

                Form::Element::Layout::Condition(type: all_types_except_table) do
                end
              end

              Form::Element::Layout::Page(label: I18n.t('crm.chart.settings.animations'), icon: "wand-magic-sparkles", initialize_hidden_element: true) do
                H3(class: "mb-3") do
                  I18n.t('crm.chart.settings.animations')
                end

                Form::Element::Attribute::Integer(attribute_name: 'transition_duration')
                Form::Element::Attribute::Integer(attribute_name: 'transition_delay')

              end

              DIV(class: 'mt-auto pt-5') do
                Form::Footer(show_submit_button_from_page_number: 3) do
                  Form::Element::Control::Breadcrumb()
                end
              end

            end.on(:success) do
              dashboard.stale!
              dashboard.mutate
              close_right_panel
            end
          end
        end
      end

      def chart_klasses
        #return ::Dynamic::Chart::Base.subclasses
        return [
          Dynamic::Chart::Pie,
          Dynamic::Chart::Row,
          Dynamic::Chart::Bar,
          #Dynamic::Chart::Sunburst,
          Dynamic::Chart::Line,
          #Dynamic::Chart::Bubble,
          #Dynamic::Chart::ScatterPlot,
          #Dynamic::Chart::BoxPlot,
          #Dynamic::Chart::HeatMap,
          #Dynamic::Chart::Composite,
          #Dynamic::Chart::Series,
          #Dynamic::Chart::GeoChoropleth,
          #Dynamic::Chart::DataCount,
          #Dynamic::Chart::DataGrid,
          #Dynamic::Chart::DataTable,
          Dynamic::Chart::Table,
          #Dynamic::Chart::BubbleOverlay,
          Dynamic::Chart::NumberDisplay,
        ]
      end

      def build_y_axis(max: nil)
        Form::Element::Association::HasMany(
          attribute_name: 'y_groups',
          mode: 'nested_form',
          show_label: false,
          max: max,
        ) do
          Form::Element::Attribute::Enum(attribute_name: 'axis', editor: 'hidden', default_value: 'y')

          attr_or_script

          Form::Element::Layout::Condition(value_type: ['string']) do
            Form::Element::Attribute::Enum(attribute_name: 'agg', possible_values: possible_aggs(['cardinality']), default_value: 'cardinality', requirement: 'mandatory', accept_empty_value: false)
          end
          Form::Element::Layout::Condition(value_type: ['number']) do
            Form::Element::Attribute::Enum(attribute_name: 'agg', possible_values: possible_aggs(['avg', 'max', 'min', 'median', 'sum', 'percentile_ranks', 'percentiles', 'extended_stats', 'top_hits', 'cardinality']), default_value: 'avg', requirement: 'mandatory', accept_empty_value: false)
          end
          Form::Element::Layout::Condition(value_type: ['boolean']) do
            Form::Element::Attribute::Enum(attribute_name: 'agg', possible_values: possible_aggs(['cardinality']), default_value: 'cardinality', requirement: 'mandatory', accept_empty_value: false)
          end
          Form::Element::Layout::Condition(value_type: ['date']) do
            Form::Element::Attribute::Enum(attribute_name: 'agg', possible_values: possible_aggs(['cardinality']), default_value: 'cardinality', requirement: 'mandatory', accept_empty_value: false)
          end
        end
      end

      def build_z_axis
        Form::Element::Association::HasMany(
          attribute_name: 'z_groups',
          mode: 'nested_form',
          show_label: false,
          min: 0,
          max: 1
        ) do |index|
          Form::Element::Attribute::Enum(attribute_name: 'axis', editor: 'hidden', default_value: 'z')

          attr_or_script

          Form::Element::Attribute::Enum(attribute_name: 'agg', possible_values: possible_aggs(['terms']), default_value: 'terms')
          Form::Element::Attribute::Integer(attribute_name: 'size', default_value: 5, min: 1, max: 100, requirement: 'mandatory')
        end
      end

      def build_x_axis(add_histogram: false)
        number_aggs = ['terms', 'range']
        date_aggs   = ['terms']
        if add_histogram
          number_aggs << 'histogram'
          date_aggs   << 'auto_date_histogram'
        end

        Form::Element::Association::HasMany(
          attribute_name: 'x_groups',
          mode: 'nested_form',
          show_label: false,
          min: 1,
        ) do
          Form::Element::Attribute::Enum(attribute_name: 'axis', editor: 'hidden', default_value: 'x')
          attr_or_script

          Form::Element::Layout::Condition(value_type: ['string', 'boolean']) do
            Form::Element::Attribute::Enum(attribute_name: 'agg', editor: 'hidden', default_value: 'terms')
          end

          Form::Element::Layout::Condition(value_type: ['date']) do
            if add_histogram
              Form::Element::Attribute::Enum(attribute_name: 'agg', possible_values: possible_aggs(date_aggs), default_value: 'terms', requirement: 'mandatory', accept_empty_value: false)
            else
              Form::Element::Attribute::Enum(attribute_name: 'agg', editor: 'hidden', default_value: 'terms')
            end
          end

          Form::Element::Layout::Condition(value_type: ['number']) do
            Form::Element::Attribute::Enum(attribute_name: 'agg', possible_values: possible_aggs(number_aggs), default_value: 'terms', requirement: 'mandatory', accept_empty_value: false)
            Form::Element::Attribute::String(attribute_name: 'min')
            Form::Element::Attribute::String(attribute_name: 'max')
          end

          Form::Element::Layout::Condition(value_type: ['date']) do
            Form::Element::Attribute::Enum(
              attribute_name: 'calendar_interval',
              possible_values: calendar_interval_possible_values(['1d', '1s']),
              default_value: '1s',
              accept_empty_value: false,
            )
          end
          Form::Element::Attribute::Integer(attribute_name: 'size', default_value: 10, min: 1, max: 100)
          Form::Element::Attribute::Boolean(attribute_name: 'show_others', default_value: false).on(:change) do |val, form, element|
            root = element.prefix_path[0]
            path = [root, 'y_groups']
            ygs = form.submission.read(path)

            #If there are any y_groups present, `show_others` must be forced to 0
            if ygs.present? && val == '1'
              form.submission.write_from_user(element.prefix_path + ['show_others'], '0')
            end
          end
          Form::Element::Attribute::Boolean(attribute_name: 'show_missing', default_value: false)

          Form::Element::Layout::Condition(agg: ['range', 'date_range']) do
            Form::Element::Association::HasMany(
              attribute_name: 'ranges',
              mode: 'nested_form',
            ) do
              Form::Element::Attribute::String(attribute_name: 'from')
              Form::Element::Attribute::String(attribute_name: 'to')
            end
            Form::Element::Control::AddButton(attribute_name: 'ranges')
          end
        end
      end

      def build_x_axis_one_value
        Form::Element::Association::HasMany(
          attribute_name: 'x_groups',
          mode: 'nested_form',
          show_label: false,
          min: 1,
        ) do
          Form::Element::Attribute::Enum(attribute_name: 'axis', editor: 'hidden', default_value: 'x')
          attr_or_script
          Form::Element::Layout::Condition(value_type: ['string']) do
            Form::Element::Attribute::Enum(attribute_name: 'agg', possible_values: possible_aggs(['cardinality']), default_value: 'cardinality', requirement: 'mandatory', accept_empty_value: false)
          end
          Form::Element::Layout::Condition(value_type: ['number']) do
            Form::Element::Attribute::Enum(attribute_name: 'agg', possible_values: possible_aggs(['avg', 'max', 'min', 'median', 'sum', 'percentile_ranks', 'percentiles', 'extended_stats', 'top_hits', 'cardinality']), default_value: 'avg', requirement: 'mandatory', accept_empty_value: false)
          end
          Form::Element::Layout::Condition(value_type: ['boolean']) do
            Form::Element::Attribute::Enum(attribute_name: 'agg', possible_values: possible_aggs(['cardinality']), default_value: 'cardinality', requirement: 'mandatory', accept_empty_value: false)
          end
          Form::Element::Layout::Condition(value_type: ['date']) do
            Form::Element::Attribute::Enum(attribute_name: 'agg', possible_values: possible_aggs(['cardinality']), default_value: 'cardinality', requirement: 'mandatory', accept_empty_value: false)
          end
        end
      end

      def attr_or_script
        Form::Element::Attribute::Enum(attribute_name: 'source', editor: 'hidden', default_value: 'attr')

        Form::Element::Layout::Condition(source: 'attr') do
          Form::Element::Attribute::SerializedArray(attribute_name: 'attr', accept_empty_value: true, placeholder: '', possible_values: possible_attrs, requirement: 'mandatory', selectable_expandable_option: false).on(:change) do |attr, form, element|
            element_prefix_path = element.prefix_path
            form.submission.write_from_user(element_prefix_path + ['value_type'], value_type_for_attr(attr.split('.')))
            I18n.available_locales.each do |locale|
              translation = klass.human_attribute_name(attr, locale: locale)
              record.send("human_name_#{locale}=", translation)
            end
            if element_prefix_path[1] == 'y_groups'
              form.submission.write_from_user([element_prefix_path[0], 'x_groups', 0, 'show_others'], '0')
            end

            mutate
          end
          Form::Element::Attribute::Enum(attribute_name: 'value_type', requirement: 'mandatory', editor: 'hidden')
        end

        Form::Element::Layout::Condition(source: 'script') do
          Form::Element::Attribute::TranslatableString(attribute_name: 'human_name')
          Form::Element::Attribute::Enum(attribute_name: 'value_type', placehodler: '', requirement: 'mandatory')
          Form::Element::Attribute::Text(attribute_name: 'script', editor: 'textarea', requirement: 'mandatory')
        end
      end

      def options_for_indexed_json_to_options(klass, options, prefix = '')
        return unless options
        results = []
        options[:only].each do |attr|
          results << {
            label: klass.human_attribute_name(attr),
            value: "#{prefix}#{attr}",
          }
        end if options[:only]

        options[:include].each do |asso, asso_options|
          next unless klass.reflect_on_association(asso) && klass.reflect_on_association(asso)&.options[:class_name]
          k = klass.reflect_on_association(asso)&.options[:class_name].safe_constantize
          results << {
            label: klass.human_attribute_name(asso),
            options: options_for_indexed_json_to_options(k, asso_options, "#{prefix}#{asso}."),
          }
        end if options[:include]
        return results.sort_by{|r| r[:label]}
      end

      def possible_attrs
        observe options_for_indexed_json = klass.options_for_indexed_json
        options_for_indexed_json_to_options(klass, options_for_indexed_json) if options_for_indexed_json
      end

      def possible_aggs(aggs)
        aggs.map do |agg|
          {
            label: ::Dynamic::Chart::Group.human_attribute_value(:agg, agg),
            value: agg,
          }
        end
      end

      def record
        return @record if @record
        result = case request.params[:action]
        when 'edit'
          record_klass.with_includes_for_load.find(request.params[:id]) if request.params[:id]
        when 'new'
          if dashboard&.loaded?
            record_klass.new(
              dashboard_id: dashboard.id,
              klass_name: klass.name,
              type: ::Dynamic::Chart::Base.subclasses.first&.name&.demodulize,
            )
          end
        end
        @record = result
        return result
      end

      def record_klass
        schema.const::R::Chart::Base
      end

      def request
        other_params[:path] ? ::Router::Resources::Request.new(other_params[:path]) : super
      end

      def klass
        case request.params[:action]
        when 'new'
          request.params[:klass_name]&.safe_constantize
        else 'edit'
          record&.klass_name&.safe_constantize
        end
      end

      def dashboard
        return observe @dashboard if @dashboard
        dashboard_klass = schema.const::R::Dashboard
        @dashboard = dashboard_klass.with_includes_for_load.find(dashboard_id)
        return observe @dashboard if @dashboard
      end

      def dashboard_id
        request.params[:dashboard_id]
      end

      after_new_params do
        if klass && @previous_klass != klass
          @dashboard = nil
          @previous_klass = klass
          @record = nil
        end
        if request.params[:action] != @previous_action || request.params[:id] != @previous_id
          @record = nil
          @previous_action = request.params[:action]
          @previous_id = request.params[:id]
        end
      end

      def type_of_attr_is_in(types)
        Proc.new do |r, _|
          types.include?(klass.attributes.dig(r.attr, 'type'))
        end
      end

      def value_type_for_attr(attr_path, klass=self.klass)
        if klass.indexed_type_for_attributes.has_key?(attr_path[0])
          klass.indexed_type_for_attributes[attr_path[0]]
        elsif klass.reflect_on_association(attr_path[0])
          value_type_for_attr(attr_path[1..-1], klass.reflect_on_association(attr_path[0])&.options[:class_name].constantize)
        end
      end

      def calendar_interval_possible_values(intervals)
        intervals.map do |interval|
          { value: interval, label: ::Dynamic::Chart::Group.human_attribute_value(:calendar_interval, interval) }
        end
      end

      def close_right_panel
        App.history.push(App.location.remove_param(panel_param(other_params[:side]))) # close panel
      end

      def all_types_except_table
        return [nil] + Dynamic::Chart::Base.subclasses.map{|n| n.name.demodulize} - ['Table']
      end

    end
  end
end
