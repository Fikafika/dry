# backtick_javascript: true

class Crm
  module Chart

    def self.create_element(params)
      return unless params[:type]
      component = "::Crm::Chart::#{params[:type]}".safe_constantize
      return unless component
      component.create_element(params).render(params)
    end

    class Base < ::Crm::Base

      include WithMeasure
      with_measure ['width', 'height']

      disable_auto_unmount_instance_variables # for more details, check docs/frontend/dashboard_fullscreen_unmount_cascade.md

      param :registry

      collect_other_params_as :other_params

      render { content }

      def content
        layout
      end

      def buttons
        DIV(class: 'position-absolute d-flex flex-wrap justify-content-end align-items-start w-100', style: { top: 0, right: 0, gap: '4px' }) do
          chart_search_input
          reset_filter_btn
          reset_sort_btn
          expand_fullscreen_btn
        end
      end

      def fullscreen_applicable?
        true
      end

      def search_applicable?
        true
      end

      def expand_fullscreen_btn
        return if uuid.to_s.include?('-fullscreen') || !fullscreen_applicable?
        A(href: '#expand', class: 'btn btn-sm btn-light', title: I18n.t('shared.fullscreen')) do
          I(class: 'fas fa-expand')
        end.on(:click) do |event|
          event.prevent_default
          registry&.open_fullscreen_chart(other_params[:id])
        end
      end

      def reset_filter_btn
        A(href: '#reset', class: 'btn btn-sm btn-light', style: { display: any_chart_filter_active? ? '' : 'none' }) do
          I(class: 'fa fa-reply')
        end.on(:click) do |event|
          event.prevent_default
          event.stop_propagation
          clear_chart_state_key('exclusion_filters')
          clear_chart_state_key('contains')
          if has_filter
            filter_all
          else
            registry.search
          end
          update
        end
      end

      def reset_sort_btn
        A(href: '#reset_sort', class: 'reset_sort btn btn-sm btn-light position-relative', style: {display: 'none'}) do
          I(class: 'fa fa-sort-amount-asc')
          I(class: 'fa fa-xmark fa-stack-1x', style: {font_size: '1em', color: '#575c5c'})
        end.on(:click) do |event|
          event.prevent_default
          clear_chart_state_key('order')
          registry.search
          update
        end
      end

      def human_name_text
        return unless other_params[:render_human_name]
        H5(class: 'text-center') do
          other_params[:human_name]
        end
      end

      def layout
        DIV(id: "chart-#{uuid}", class: "#{layout_padding} #{other_params[:className]} h-100 overflow-hidden") do
          STYLE {render_rotation_style} if other_params[:rotation_degree_x] || other_params[:rotation_degree_y]
          DIV(class: 'float-left position-relative w-100') do
            human_name_text
            buttons
          end
          DIV(class: 'on-hover', style: {display: 'none'}) do
            axis_sort_buttons
            pagination_buttons
          end

          DIV(class: 'clearfix')
          placeholder
          yield if block_given?
        end.on(:mouse_enter) do
          self.jq_node.find('.edit').show();
          self.jq_node.find('.on-hover').show();
        end.on(:mouse_leave) do
          self.jq_node.find('.edit').hide();
          self.jq_node.find('.on-hover').hide();
        end
      end

      def render_rotation_style
        return [
          rotation_style("g.x", other_params[:rotation_degree_x]),
          rotation_style("g.y", other_params[:rotation_degree_y], apply_anchor: false)
        ].join("\n")
      end

      def rotation_style(selector, degree, apply_anchor: true)
        return "" if degree.nil?
        css = "#chart-#{uuid} #{selector} .tick text { transform: rotate(#{degree}deg);"
        css += "text-anchor: #{degree > 0 ? 'start' : (degree < 0 ? 'end' : 'middle')};" if apply_anchor
        return css + "}"
      end

      def axis_sort_buttons
        return if is_a?(::Crm::Chart::Table)
        assign_sort_from_search_query?
        valid = %w[asc desc]
        current = other_params[:sort] ||= {}
        x = current['x']
        y = current['y']
        current['x'] = valid.include?(x) ? x : nil
        current['y'] = valid.include?(y) ? y : nil
        DIV(class: 'axis-sort-buttons position-absolute d-flex', style: { bottom: '2px', right:'2px', zIndex: 1}) do
          title = I18n.t('crm.chart.sort.sort_by_key')
          label = I18n.t("crm.chart.sort.axis.#{current['x'] || 'none'}")
          A(href: '#', class: "axis-sort-btn axis-sort-x btn btn-sm btn-outline-secondary", title: "#{title} : #{label}") do
            I(class: "fa fa-sort-amount-#{current['x'] || 'asc'}")
          end.on(:click) do |event|
            event.prevent_default
            event.stop_propagation
            apply_axis_sort('x')
            mutate
          end
        end
        DIV(class: 'axis-sort-buttons position-absolute d-flex', style: {top: '2px', left: '2px', zIndex: 1}) do
          title = I18n.t('crm.chart.sort.sort_by_value')
          label = I18n.t("crm.chart.sort.axis.#{current['y'] || 'none'}")
          A(href: '#', class: "axis-sort-btn axis-sort-y btn btn-sm btn-outline-secondary", title: "#{title} : #{label}") do
            I(class: "fa fa-sort-amount-#{current['y'] || 'asc'}")
          end.on(:click) do |event|
            event.prevent_default
            event.stop_propagation
            apply_axis_sort('y')
            mutate
          end
        end
      end


      def apply_axis_sort(axis)
        registry.search_query[self.url_id] ||= {}

        other_params[:sort] ||= {'y' => nil, 'x' => nil}
        state = other_params[:sort][axis] || 'asc'
        other_params[:sort][axis] = (state == 'asc') ? 'desc' : 'asc'

        registry.search_query[self.url_id]['order'] = other_params[:sort]
        registry.search
      end

      def convert_sort_from_search_query(s)
        return {"x"=>nil, "y"=>nil} if s.nil?
        return s if s.is_a?(Hash) && (s.key?('x') || s.key?('y'))
        {"x"=>nil, "y"=>nil}
      end

      def get_sort_value_from_axis(q, axis)
        q.is_a?(Hash) ? q[axis] : nil
      end

      def sorts_from_search_query_equals_sorts_from_dc?(sorts_from_search_query)
        lhs = {'x' => get_sort_value_from_axis(sorts_from_search_query, 'x'), 'y' => get_sort_value_from_axis(sorts_from_search_query, 'y')}
        rhs = {'x' => get_sort_value_from_axis(other_params[:sort], 'x'), 'y' => get_sort_value_from_axis(other_params[:sort], 'y')}
        lhs == rhs
      end

      def assign_sort_from_search_query?
        s = convert_sort_from_search_query(registry.search_query&.dig(self.url_id, 'order'))
        not_changed = sorts_from_search_query_equals_sorts_from_dc?(s)
        return false if s.nil? || not_changed
        other_params[:sort] ||= {'y' => nil, 'x' => nil}
        other_params[:sort]['x'] = s.key?('x') ? s['x'] : nil
        other_params[:sort]['y'] = s.key?('y') ? s['y'] : nil
        true
      end

      def set_sort_from_dashboard
        return unless registry
        changed = assign_sort_from_search_query?
        if registry.charts[uuid] && changed
          assign_sort_from_search_query?
          sort_data = registry.search_query&.dig(self.url_id, 'order')
          if sort_data
            if sort_data.nil? || sort_data.empty? || sort_data['x'].nil? && sort_data['y'].nil?
              clear_chart_state_key('order')
            end
          end
          update
          mutate
        end
      end

      def chart_search_input
        return unless search_applicable?
        contains_chart_input_from_search_query
        DIV(class: "on-hover chart-search input-group input-group-sm w-auto", style: { display: 'none', maxWidth: '50%' }) do
          if x_group_enum_mapping
            render_chart_search_enum_dropdown
          else
            render_chart_search_input
          end
        end
      end

      def render_chart_search_input
        type = x_group&.value_type == 'date' ? 'date' : 'text'
        INPUT(class: 'form-control', type: type, value: @chart_input_value).on(:change) do |event|
          @chart_input_value = event.target.value
          mutate
        end.on(:key_press) do |event|
          if event.which == 13
            event.stop_propagation
            event.prevent_default
            apply_chart_search
          end
        end

        BUTTON(class: "btn btn-sm #{chart_input_changed? ? 'btn-primary' : 'btn-secondary'}", disabled: !chart_input_changed?) do
          SPAN(class: 'fa-solid fa-magnifying-glass')
        end.on(:click) do |event|
          event.stop_propagation
          event.prevent_default
          apply_chart_search
        end
      end

      def render_chart_search_enum_dropdown
        mapping = x_group_enum_mapping
        DIV(class: 'dropdown flex-grow-1') do
          BUTTON(class: 'btn btn-sm btn-light dropdown-toggle', type: 'button', 'data-toggle': 'dropdown') do
            mapping[@chart_input_value] || I18n.t('shared.select')
          end
          DIV(class: 'dropdown-menu') do
            A(class: 'dropdown-item', href: '#') do
              I18n.t('shared.clear')
            end.on(:click) do |event|
              event.stop_propagation
              event.prevent_default
              @chart_input_value = ''
              apply_chart_search
            end
            mapping.each do |val, label|
              A(class: 'dropdown-item', href: '#') do
                label
              end.on(:click) do |event|
                event.stop_propagation
                event.prevent_default
                @chart_input_value = val.to_s
                apply_chart_search
              end
            end
          end
        end
      end

      def x_group_enum_mapping
        return unless x_group&.source == 'attr'
        other_params[:klass_name]&.safe_constantize&.attributes&.dig(x_group.attr, 'mapping_invert', I18n.locale)
      end

      def chart_input_changed?
        @chart_input_value != @chart_original_input_value
      end

      def contains_chart_input_from_search_query
        from_url = registry.search_query[self.url_id]&.dig('contains').to_s
        return if @chart_original_input_value == from_url
        @chart_original_input_value = @chart_input_value = from_url
      end

      def set_contains_from_dashboard
        return unless registry
        contains_chart_input_from_search_query
        mutate
      end

      def apply_chart_search
        @chart_original_input_value = @chart_input_value
        val = @chart_input_value.to_s
        registry.search_query[self.url_id] ||= {}

        if val.present?
          registry.search_query[self.url_id]['contains'] = val
        else
          registry.search_query[self.url_id].delete('contains')
          registry.search_query.delete(self.url_id) if registry.search_query[self.url_id].empty?
        end

        registry.search
      end

      def layout_padding
        'p-0'
      end

      def placeholder
        SVG(style: placeholder_style, class: 'd-none') # this element prepare space and will be replaced by dc.js
      end

      def placeholder_style
        result = {}
        mw = other_params[:minWidth] || other_params[:width]
        mh = other_params[:minHeight] || other_params[:height]
        result[:minWidth] = "#{mw}px" if mw
        result[:minHeight] = "#{mh}px" if mh
        return result
      end

      before_unmount do
        registry.deregister(uuid)
        @native = nil
      end

      after_mount do
        init
      end

      after_render do
        update_or_init
      end

      def update_or_init
        if registry.charts[uuid]
          update
          if uuid.to_s.end_with?('-fullscreen')
            native_render
          end
        else
          init
        end

        unless sorted?
          hide_reset_sort_btn
        else
          show_reset_sort_btn
        end
      end

      def sorted?
        unless registry&.search_query[self.url_id]
          return false
        end
        registry&.search_query[self.url_id]['order']
      end

      def hide_reset_sort_btn
        self.jq_node.find('.reset_sort').hide
      end

      def show_reset_sort_btn
        fullscreen_uuid = "#{uuid}-fullscreen"
        registry&.charts[fullscreen_uuid]&.jq_node&.find('.reset_sort')&.show()
        self.jq_node.find('.reset_sort').show
      end

      def uuid
        other_params[:uuid]
      end

      def init
        registry&.register(uuid, self)
        css_id = dc_css_id
        chart_type = self.dc_chart_type
        @native =`new dc[chart_type](css_id)`
        z_g = z_group
        if z_g
          build_z_stacks(z_g)
        else
          build_y_stacks
        end

        if registry
          f = convert_filter_from_search_query(registry.search_query&.dig(self.url_id,'filters'))
          self.filter(f) unless f.nil?
        end

        # React attaches onWheel in passive mode (preventDefault is ignored there) so we attach our own non-passive native listener to block scrolling while zooming.
        if pagination_applicable?
          on_wheel = Proc.new do |e|
            `#{e}.preventDefault()`
            update_size(`#{e}.deltaY` > 0 ? 1 : -1)
          end.to_n
          `document.querySelector(css_id).addEventListener('wheel', #{on_wheel}, {passive: false})`
        end

        self.dimension = OpenStruct.new(
          filter: Proc.new do |value|
            next if @set_filter_from_dashboard
            with_delay do  # wait because filters are wrong when reset filters
              search
            end
          end,
          filterFunction: Proc.new do |value|
            next if @set_filter_from_dashboard
            with_delay do
              search
            end
          end,
          filterExact: Proc.new do |value|
            next if @set_filter_from_dashboard
            with_delay do
              search
            end
          end,
          filterRange: Proc.new do |value|
            next if @set_filter_from_dashboard
            with_delay do
              search
            end
          end,
        )
        settings.each do |k,v|
          send("#{k}=", v)
        end

        if zoom_applicable?
          active_filters = self.filters
          if active_filters&.any?
            domain = filters_to_domain(active_filters)
            self.x = `#{@native}.x().copy().domain(#{domain.to_n})` if domain&.any?
          end
        end

        set_label_and_legend_translations
        if uuid.to_s.end_with?('-fullscreen')
          native_render
        end
      end

      def search
        f = self.filters
        if f&.any?
          registry.search_query[self.url_id] ||= {}
          registry.search_query[self.url_id]['filters'] = f
        elsif registry.search_query[self.url_id]
          registry.search_query[self.url_id].delete('filters')
          if registry.search_query[self.url_id].empty?
            registry.search_query.delete(self.url_id)
          end
        end
        registry.search
      end

      def with_delay
        return if @searching
        @searching = true
        @delay&.abort
        @delay = after!(0.1) do
          yield
          @searching = false
        end
        @delay.start
      end

      def update
        settings(true).each do |k,v|
          send("#{k}=", v)
        end

        set_label_and_legend_translations(true)
      end

      def set_filter_from_dashboard
        return unless registry
        f = convert_filter_from_search_query(registry.search_query&.dig(self.url_id, 'filters'))
        return if filters_from_search_query_equals_filters_from_dc?(f)
        @set_filter_from_dashboard = true # prevent cycles
        if f
          self.replace_filter(f)
        elsif self.filters&.any?
          self.filter(`null`) # ?
        end
        @set_filter_from_dashboard = false
      end

      def filters_from_search_query_equals_filters_from_dc?(filters_from_search_query = convert_filter_from_search_query(registry.search_query&.dig(self.url_id, 'filters')))
        filters_from_search_query == self.filters
      end

      def convert_filter_from_search_query(f)
        return nil if f.nil?
        if f.is_a?(Array)
          f = f.map do |e|
            if e.is_a?(String) && e =~ /^\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d \+\d\d\d\d$/
              e = Time.parse(e)
            end
            e
          end
        end
        f = [f] if f && !self.is_a?(Crm::Chart::Line)
        return f
      end

      def current_keys
        data = registry.response.dig(:charts)&.detect{|c| c[:uuid] == other_params[:id]}.try(:[], :data) || []
        special = data.count { |h| h["key"] == "_others_" || h["key"] == "_missing_" }
        data.count - special
      end

      def current_key
        @current_key
      end

      def set_current_key(key)
        @current_key = key
      end

      def show_button(class_name:, action:, icon:, text:, disabled: false)
        BUTTON(class: class_name, disabled: disabled) do
          I(class: icon)
          text
        end.on(:click) do |event|
          event.prevent_default
          action.call
        end
      end

      def drill
        registry.search_query.dig(self.url_id, 'drill') || 0
      end

      def drill=(value)
        registry.search_query[self.url_id] ||= {}
        if value != 0
          registry.search_query[self.url_id]['drill'] = value
        else
          registry.search_query[self.url_id].delete('drill')
          registry.search_query.delete(self.url_id) if registry.search_query[self.url_id].empty?
        end
      end

      def do_drill_down
        keys = current_keys
        return if keys == 0

        self.drill = drill + keys
        registry.search
      end

      def do_drill_up
        return if drill == 0
        keys = current_keys
        step = keys > 0 ? keys : (x_group&.size || 10).to_i
        self.drill = [drill - step, 0].max
        registry.search
      end

      def reset_drill
        self.drill = 0
        registry.search
      end

      def show_drill_up_button?
        return drill != 0
      end

      def show_drill_down_button?
        return current_keys != 0
      end

      def exclusion_filters
        registry.search_query&.dig(self.url_id, 'exclusion_filters') || []
      end

      def do_exclude_key(key)
        registry.search_query[self.url_id] ||= {}
        registry.search_query[self.url_id]['exclusion_filters'] ||= []
        return if exclusion_filters.include?(key)

        exclusion_filters.push(key)
        registry.search
      end

      def undo_exclude_key
        return if exclusion_filters.empty?

        exclusion_filters.pop
        registry.search
      end

      def reset_exclusion
        clear_chart_state_key('exclusion_filters')
        registry.search
      end

      def exclusion_filters_any?
        exclusion_filters.any?
      end

      def show_others_state?
        x_group.show_others
      end

      def show_missing_state?
        x_group.show_missing
      end

      def update_show_missing(new_value)
        x_group_record = x_group
        return unless x_group_record
        x_group_record.update(show_missing: new_value).then do |response|
          if response[:success]
            update
            registry.render_or_redraw(force: true)
            mutate
          end
        end
      end

      def update_show_others(new_value)
        x_group_record = x_group

        return unless x_group_record

        x_group_record.update(show_others: new_value).then do |response|
          if response[:success]
            update
            registry.render_or_redraw(force: true)
            mutate
          end
        end
      end

      def pagination_applicable?
        false
      end

      def pagination_buttons
      end

      def zoom_applicable?
        false
      end

      def clear_chart_state_key(key)
        return unless registry.search_query[self.url_id]
        registry.search_query[self.url_id].delete(key)
        registry.search_query.delete(self.url_id) if registry.search_query[self.url_id].empty?
      end

      def any_chart_filter_active?
        has_filter || exclusion_filters_any? || registry.search_query&.dig(self.url_id, 'contains').present?
      end

      def filters_to_domain(filters)
        return filters unless x_group.value_type == 'date'
        [safe_date(filters[0], `new Date(1970, 0, 1)`), safe_date(filters[1], `new Date()`)]
      end

      def safe_date(value, fallback)
        return fallback if value.nil?
        date = `new Date(#{value})`
        `isNaN(#{date}.getTime())` ? fallback : date
      end

      def zoom_pretransition(chart)
        return unless zoom_applicable?
        return if @applying_zoom

        active_filters = self.filters

        if active_filters&.any?
          domain = filters_to_domain(active_filters)
          return unless domain&.any?
          cd = `#{chart}.x().domain()`
          return if `#{domain.to_n}[0].valueOf() === #{cd}[0].valueOf() && #{domain.to_n}[1].valueOf() === #{cd}[1].valueOf()`
        else
          data = registry.response.dig(:charts)&.detect{|c| c[:uuid] == other_params[:id]}&.[](:data) || []
          return if data.equal?(@last_data)
          @last_data = data
          domain = x_domain_from_groups
          return unless domain&.any?
        end

        `
          var c = #{@native};
          var dom = #{domain.to_n};
          var org = #{x_domain_from_groups.to_n};
          c.x(c.x().copy().domain(dom));
          c._xOriginalDomain = org;
          c._origX = c.x().copy().domain(org);
          if (c._zoom && c.root()) {
            c.root().property('__zoom', c._domainToZoomTransform(dom, org, c._origX));
          }
          c._resizing = true;
        `
        @applying_zoom = true
        self.redraw
        @applying_zoom = false
      end

      def update_size(delta)
        @pending_zoom_delta = (@pending_zoom_delta || 0) + delta
        @zoom_delay&.abort
        @zoom_delay = after!(0.1) do
          flush_update_size
        end
        @zoom_delay.start
      end

      def flush_update_size
        delta = @pending_zoom_delta
        @pending_zoom_delta = 0
        x_group_record = x_group
        return unless x_group_record
        current_size = [(x_group_record.size || 10).to_i, current_keys].min

        new_size = [[(current_size + delta), 1].max, 100].min
        return if new_size == current_size
        x_group_record.update(size: new_size).then do |response|
          if response[:success]
            registry.render_or_redraw(force: true)
          end
        end
      end

      def context_buttons
        current_key_ = current_key

        exclusion_filters_empty = exclusion_filters.empty?

        drill_down_enabled = show_drill_down_button?
        drill_up_enabled   = show_drill_up_button?

        if current_key_ == '_others_'
          show_button(class_name: 'btn btn-link dropdown-item', disabled: !drill_down_enabled, icon: 'fa fa-level-down fa-fw pr-3', text: I18n.t('crm.chart.drill.down'), action: -> { do_drill_down })
          show_button(class_name: 'btn btn-link dropdown-item', disabled: !drill_up_enabled, icon: 'fa fa-level-up fa-fw pr-3', text: I18n.t('crm.chart.drill.up'), action: -> { do_drill_up })
          show_button(class_name: 'btn btn-link dropdown-item', disabled: !drill_up_enabled, icon: 'fa fa-undo fa-fw pr-3', text: I18n.t('crm.chart.drill.reset'), action: -> { reset_drill })
        else
          if current_key_.present?
            if current_key_ !=  "_missing_"
              show_button(class_name: 'btn btn-link dropdown-item', icon: 'fa fa-ban fa-fw pr-3', text: "#{I18n.t('crm.chart.exclude.key')} #{current_key_}", action: -> { do_exclude_key(current_key_) })
              show_button(class_name: 'btn btn-link dropdown-item', disabled: exclusion_filters_empty, icon: 'fa fa-undo fa-fw pr-3', text: I18n.t('crm.chart.exclude.undo'), action: -> { undo_exclude_key })
              show_button(class_name: 'btn btn-link dropdown-item', disabled: exclusion_filters_empty, icon: 'fa fa-trash-alt fa-fw pr-3', text: I18n.t('crm.chart.exclude.reset'), action: -> { reset_exclusion })
            end
          else
            show_button(class_name: 'btn btn-link dropdown-item', disabled: !drill_up_enabled, icon: 'fa fa-undo fa-fw pr-3', text: I18n.t('crm.chart.drill.reset'), action: -> { reset_drill }) unless (self.is_a?(Crm::Chart::Line) || self.is_a?(Crm::Chart::Bar)) && x_group.value_type != 'string'
            show_button(class_name: 'btn btn-link dropdown-item', disabled: exclusion_filters_empty, icon: 'fa fa-trash-alt fa-fw pr-3', text: I18n.t('crm.chart.exclude.reset'), action: -> { reset_exclusion })
          end

        end

        unless (self.is_a?(Crm::Chart::Line) || self.is_a?(Crm::Chart::Bar)) && x_group.value_type != 'string'
          show_others_enabled = show_others_state?
          show_missing_enabled = show_missing_state?

          icon_class_missing = show_missing_enabled ? 'fa fa-eye-slash fa-fw pr-3' : 'fa fa-eye fa-fw pr-3'
          new_value_missing = !show_missing_enabled
          icon_class = show_others_enabled ? 'fa fa-eye-slash fa-fw pr-3' : 'fa fa-eye fa-fw pr-3'
          new_value = !show_others_enabled

          unless y_groups.present?
            show_button(class_name: 'btn btn-link dropdown-item', icon: icon_class, text: I18n.t("crm.chart.show_others.#{new_value ? 'enable' : 'disable'}"), action: -> { update_show_others(new_value) })
          end
          show_button(class_name: 'btn btn-link dropdown-item', icon: icon_class_missing, text: I18n.t("crm.chart.show_missing.#{new_value_missing ? 'enable' : 'disable'}"), action: -> { update_show_missing(new_value_missing) })
        end
        set_current_key("")
      end

      def dc_chart_type
        result = self.class.name.demodulize
        return result if `dc[result]`
        result = "#{result}Chart"
        return result if `dc[result]`
        return nil
      end

      def dc_css_id
        @dc_css_id ||= "#chart-#{uuid}"
      end

      def url_id
        self.class.url_id((other_params[:id] || uuid).to_s)
      end

      def self.url_id(uuid)
        "chart-#{uuid[-8..-1]}"
      end

      def pretransition
        Proc.new do |chart|
          attach_context_menu_listener(chart)
        end.to_n
      end

      def x_from_groups=(v)
        return unless v && x_group && scale
        self.x = `#{scale}.domain(#{x_domain_from_groups.to_n})`
      end

      def x_domain_from_groups
        g = x_group
        case g.value_type
        when 'date'
          min = cast_from_value_type(g.min) || `new Date(1970, 01, 01)`
          max = cast_from_value_type(g.max) || `new Date()`
          return [min, max]
        when 'number'
          min = cast_from_value_type(g.min)
          max = cast_from_value_type(g.max)
          return (min && max) ? [min, max] : [1,10]
        else
          return []
        end
      end

      def scale
        return `d3.scaleBand()` if x_group.agg == 'range'
        case x_group.value_type
        when 'date'
          `d3.scaleTime()`
        when 'number'
          `d3.scaleLinear()`
        when 'string', 'boolean'
          `d3.scaleBand()`
        end
      end

      def round_from_groups=(v)
        return unless v && x_group
        return if x_group.agg == 'range'
        case x_group.value_type
        when 'date'
          self.round = d3_time_round[x_group.calendar_interval] || d3_time_units['1d']
        when 'number'
          self.round = `Math.round`
        end
      end

      def x_units_from_groups=(v)
        return unless v && x_group
        return self.x_units = `dc.units.ordinal` if x_group.agg == 'range'
        case x_group.value_type
        when 'date'
          self.x_units = d3_time_units[x_group.calendar_interval] || d3_time_units['1d']
        when 'string', 'boolean'
          self.x_units = `dc.units.ordinal`
        end
      end

      def elastic_x_from_groups=(v)
        g = x_group
        self.elastic_x = !g || (g.min.nil? && g.max.nil?)
      end

      def x_group
        other_params[:groups]&.detect{|g| g.axis == 'x' || g.axis.nil?}
      end

      def y_groups
        other_params[:groups]&.select{|g| g.axis == 'y'} || []
      end

      def z_group
        other_params[:groups]&.detect{|g| g.axis == 'z'}
      end

      def current_z_keys
        chart_data = registry.response.dig(:charts)&.detect{|c| c[:uuid] == other_params[:id]}
        return [] unless chart_data
        chart_data[:z_keys] || []
      end

      def current_y_group_ids
        chart_data = registry.response.dig(:charts)&.detect{|c| c[:uuid] == other_params[:id]}
        return [] unless chart_data
        chart_data[:y_group_ids] || []
      end

      def build_y_stacks
        first = true
        other_params[:groups].each do |g|
          next if g.axis == 'x' && other_params[:groups].length > 1
          f = OpenStruct.new(
            all: Proc.new do
              data = registry.response.dig(:charts)&.detect{|c| c[:uuid] == other_params[:id]}.try(:[], :data) || []
              data.map{|h| {key: h['key'], value: h[g.id.to_s]}}.to_n
            end
          )
          if g.axis.nil? || first
            self.group = f
            first = false
          else
            self.stack = f
          end
        end
      end

      def build_z_stacks(z_g)
        max_z = z_g.size.to_i > 0 ? z_g.size.to_i : 10
        ygs = y_groups
        y_count = ygs.any? ? ygs.size : 1

        stacks = y_count.times.flat_map do |y_idx|
          max_z.times.map do |z_idx|
            OpenStruct.new(name: y_idx * max_z + z_idx, all: Proc.new { z_stack_data(z_idx, y_idx, ygs).to_n })
          end
        end

        stacks.each_with_index { |f, i| i == 0 ? self.group = f : self.stack = f }
      end

      def z_stack_data(z_idx, y_idx, ygs)
        chart_entry = registry.response.dig(:charts)&.detect { |c| c[:uuid] == other_params[:id] }
        data = chart_entry.try(:[], :data) || []
        z_key = current_z_keys[z_idx]
        return data.map { |h| { key: h[:key], value: 0 } } unless z_key

        if ygs.any?
          y_id = (chart_entry&.dig(:y_group_ids) || [])[y_idx]
          col_key = y_id ? "#{z_key}__#{y_id}" : z_key
        else
          col_key = z_key
        end

        data.map { |h| { key: h[:key], value: h[col_key] || 0 } }
      end

      def d3_time_units
        {
          '1d' => `d3.timeDay.count`,
          '1M' => `d3.timeMonth.count`,
          '1y' => `d3.timeYear.count`,
          '1ms' => `d3.timeMillisecond.count`,
          '1s' => `d3.timeSecond.count`,
          '1m' => `d3.timeMinute.count`,
          '1h' => `d3.timeHour.count`,
          '1w' => `d3.timeWeek.count`,
        }
      end

      def d3_time_round
        {
          '1d' => `d3.timeDay.round`,
          '1M' => `d3.timeMonth.round`,
          '1y' => `d3.timeYear.round`,
          '1ms' => `d3.timeMillisecond.round`,
          '1s' => `d3.timeSecond.round`,
          '1m' => `d3.timeMinute.round`,
          '1h' => `d3.timeHour.round`,
          '1w' => `d3.timeWeek.round`,
        }
      end

      def cast_from_value_type(v)
        return unless v.present? && x_group
        case x_group.value_type
        when 'number'
          if v.include?('.')
            v.to_f
          else
            v.to_i
          end
        when 'string'
          v
        when 'date'
          `new Date(v)`
        when 'boolean'
          (v == '1' || v == 'true')
        end
      end

      def render_legend=(v)
        if v
          self.legend = legend_highlight_selected
          @blank_legend = false
        elsif self.legend && !@blank_legend
          @blank_legend = true
          l = `dc.legend()`
          `l.render = function(){}`
          self.legend = l
        end
        @render_legend = v
      end

      def render_legend
        !!@render_legend
      end

      def legend_x=(v)
        @legend_x = v
        set_legend_position if @render_legend
      end

      def legend_y=(v)
        @legend_y = v
        set_legend_position if @render_legend
      end

      def set_legend_position
        self.legend = `dc.legend().x(#{@legend_x || 0}).y(#{@legend_y || 0})`
      end

      def legend_x
        @legend_x
      end

      def legend_y
        @legend_y
      end

      def legend_highlight_selected
        `dc.legend().highlightSelected(true)`
      end

      def settings(reload = false)
        return @settings if @settings && !reload
        result = {}

        defaults = default_settings
        self.class.settings_methods.each do |k|
          default_value = defaults[k]
          if other_params.has_key?(k) && !other_params[k].nil?
            result[k] = other_params[k]
          elsif defaults.has_key?(k)
            result[k] = default_value
          end
        end

        @settings = result

        return result
      end

      def set_label_and_legend_translations(reload = false)
        @proc_for_translate_label = nil if reload
        self.label = proc_for_translate_label
        set_legend_translations
      end

      def proc_for_translate_label
        return @proc_for_translate_label if @proc_for_translate_label
        return unless x_group&.source == 'attr'
        if x_group.value_type == 'date' && need_to_format_date?
          @proc_for_translate_label = label_translation_proc_for_date
          return @proc_for_translate_label
        end
        mapping = other_params[:klass_name]&.safe_constantize&.attributes&.dig(x_group.attr, 'mapping_invert', I18n.locale) || {}
        mapping['_others_'] = I18n.t("crm.chart._others_")
        mapping['_missing_'] = I18n.t("crm.chart._missing_")
        return unless mapping
        @proc_for_translate_label = label_translation_proc(mapping)
        return @proc_for_translate_label
      end

      def label_translation_proc_for_date
        calendar_interval_x_group = x_group.calendar_interval || '1s'
        format_string = I18n.t("format.d3_format.#{calendar_interval_x_group}")
        date_time_formatter = `d3.timeFormat(#{format_string});`
        Proc.new do |l|
          k = `l.key`
          `
            if (k === '_others_') return #{I18n.t("crm.chart._others_")};
            if (k === '_missing_') return #{I18n.t("crm.chart._missing_")};
            if (typeof k === 'number' && !isNaN(k)) {
              return #{date_time_formatter}(new Date(k));
            }
            return k;
          `
        end.to_n
      end

      def label_translation_proc(mapping)
        Proc.new do |l|
          next unless `l.key`
          k = `l.key`
          next mapping[k] || k
        end
      end

      def need_to_format_date?
        return false
      end

      def set_legend_translations
        return unless proc_for_translate_label && `#{@native}.legend()`
        `#{@native}.legend().legendText(function(d) { return #{proc_for_translate_label}({key: d.name})})`
      end

      def default_settings
        {}
      end

      def self.settings_methods
        @settings_methods ||= self.instance_methods.select{|m| m.end_with?("=") && !["===", "==", "!="].include?(m)}.map{|m| m.gsub(/=$/, '').to_sym }
      end

      def self.api_method(m, old = nil)
        old ||= m.to_s.gsub(/^native_/, '').camelize(:lower)
        define_method m do |*args, &block|
          Native.call(@native, old, *args, &block)
          self
        end
        define_method("#{m}=") do |value|
          Native.call(@native, old, Native.convert(value))
          value
        end
      end

      def self.alias_method(m, old = nil)
        old ||= m.to_s.gsub(/^native_/, '').camelize(:lower)
        define_method m do |*args, &block|
          Native.convert(Native.call(@native, old, *args, &block))
        end
      end

      def self.base_mixin
        [
          :width,
          :min_width,
          :min_height,
          :use_view_box_resizing,
          :dimension,
          :data,
          :group,
          :ordering,
          :anchor,
          :root,
          :svg,
          :svg_description,
          :keyboard_accessible,
          :filter_printer,
          :controls_use_visibility,
          :transition_duration,
          :transition_delay,
          :commit_handler,
          :has_filter_handler,
          :remove_filter_handler,
          :add_filter_handler,
          :filter,
          :filterHandler,
          :key_accessor,
          :value_accessor,
          :label,
          :render_label,
          :title,
          :render_title,
          :chart_group,
          :legend,
          :native_on,
        ].each{|m| api_method(m) }

        define_method :height do |*args, &block|
          if @native
            Native.call(@native, 'height')
          else
            @height
          end
        end

        define_method :height= do |value|
          if !other_params[:render_human_name] || value.nil? || value == 0
            if @native
              Native.call(@native, 'height', Native.convert(value))
            else
              @height = value
            end
            next value
          else
            human_name_text_height = self.mounted? ? self.jq_node.find('.float-left').height() : 32
            v = value - human_name_text_height
            if @native
              Native.call(@native, 'height', Native.convert(v))
            else
              @height = v
            end
            next v
          end
        end

        [:title, :label].each do |m|
          define_method :"#{m}=" do |value|
            if !native?(value) && value.is_a?(String)
              v = Proc.new do |p|
                value
              end.to_n
              Native.call(@native, m, v)
            elsif value
              Native.call(@native, m, value)
            end
            value
          end
        end

        define_method :"pretransition=" do  |f|
          native_on(:pretransition, f)
        end

        [
          :filter_all,
          :select,
          :select_all,
          :anchor_name,
          :reset_svg,
          :size_svg,
          :generates_svg,
          :svg_description,
          :turn_on_controls,
          :turn_off_controls,
          :check_for_mandatory_attributes,
          :native_render,
          :redraw,
          :redraw_group,
          :render_group,
          :has_filter,
          :apply_filters,
          :filter,
          :replace_filter,
          :highlight_selected,
          :fade_deselected,
          :reset_highlight,
          :on_click,
          :legendables,
          :legend_highlight,
          :legend_reset,
          :legend_toggle,
          :is_legendable_hidden,
          :expire_cache,
          :chart_id,
          :options,
          :renderlet,
        ].each{|m| alias_method(m) }
      end

      def filters
        f = Native.call(@native, 'filters')
        return nil if `#{f} == null` || f == []
        f = f.flatten if f.is_a?(Array) # why self.filters can be [["Q1"], "Q2"] ?
        return f
      end

      def filter(f) # fix bug when init chart
        f = [f] if f && !self.is_a?(Crm::Chart::Line)
        Native.call(@native, 'filter', f)
      end

      def self.coordinate_grid_mixin
        margin_mixin
        color_mixin

        [
          :resizing,
          :range_chart,
          :zoom_scale,
          :zoom_out_restrict,
          :g,
          :mouse_zoomable,
          :chart_body_g,
          :x,
          :x_units,
          :x_axis,
          :elastic_x,
          :x_axis_padding,
          :x_axis_padding_unit,
          :use_right_y_axis,
          :use_top_x_axis,
          :x_axis_label,
          :y_axis_label,
          :y,
          :y_axis,
          :elastic_y,
          :render_horizontal_grid_lines,
          :render_vertical_grid_lines,
          :y_axis_padding,
          :y_axis_padding_unit,
          :round,
          :brush,
          :clip_padding,
          :focus_chart,
          :brush_on,
          :parent_brush_on,
        ].each{|m| api_method(m) }

        [
          :rescale,
          :x_original_domain,
          :x_unit_count,
          :is_ordinal,
          :render_x_axis,
          :x_axis_length,
          :render_y_axis_label,
          :render_y_axis_at,
          :render_y_axis,
          :x_axis_min,
          :x_axis_max,
          :y_axis_min,
          :y_axis_max,
          :y_axis_height,
          :render_brush,
          :create_brush_handle_paths,
          :extend_brush,
          :brush_is_empty,
          :apply_brush_selection,
          :set_brush_extents,
          :redraw_brush,
          :fade_deselected_area,
          :resize_handle_path,
          :focus,
          :refocused,
          :g_brush,
        ].each{|m| alias_method(m) }


        [
          :x_axis_ticks,
          :y_axis_ticks,
        ].each do |p|
          attr_accessor p
          define_method :"#{p}=" do |value|
            next unless instance_variable_get(:"@#{p}") != value
            instance_variable_set(:"@#{p}", value)
            a = value || `null`
            axis = "#{p.to_s[0]}Axis"
            `#{@native}[axis]().ticks(a)`
          end
        end

        define_method :"compute_margins=" do |value|
          next  # TODO fix infinite blinking graph
          if value
            native_on("renderlet", Proc.new do |chart|
              y_width = ::Element[chart.JS.svg.JS[:_groups][0][0]].find("g.y.axis").JS[0].JS.getBBox.JS[:width]
              x_height = ::Element[chart.JS.svg.JS[:_groups][0][0]].find("g.x.axis").JS[0].JS.getBBox.JS[:height]
              unless chart.JS.margins.JS[:left] == y_width && chart.JS.margins.JS[:bottom] == x_height
                self.margins = {left: y_width, bottom: x_height, right: 0, top: 0}
                reset_svg
                native_render
              end
            end)
          end
        end

      end

      def self.color_mixin
        [
          :calculate_color_domain,
          :colors,
          :ordinal_colors,
          :color_accessor,
          :color_domain,
          :color_calculator,
          :linear_colors,
        ].each{|m| api_method(m) }
      end

      def self.stack_mixin
        coordinate_grid_mixin

        [
          :stack,
          :hidable_stacks,
          :stack_layout,
          :evade_domain_filter,
        ].each{|m| api_method(m) }

        [
          :show_stack,
          :hide_stack,
          :get_value_accessor_by_index,
          :legendables,
          :is_legendable_hidden,
          :legend_toggle,
        ].each{|m| alias_method(m) }
      end

      def self.margin_mixin
        [
          :margins,
        ].each{|m| api_method(m) }

        [:top, :right, :bottom, :left].each do |p|
          attr_accessor :"margins_#{p}"
          define_method :"margins_#{p}=" do |value|
            instance_variable_set(:"@margins_#{p}", value)
            init_margins
          end
        end
        define_method :init_margins do
          # next unless @margins_top && @margins_right && @margins_bottom && @margins_left
          self.margins = {
            top: @margins_top || 0,
            right: @margins_right || 0,
            bottom: @margins_bottom || 0,
            left: @margins_left || 0,
          }
        end

        [
          :effective_width,
          :effective_height,
        ].each{|m| alias_method(m) }

      end

      def self.cap_mixin
        [
          :cap,
          :take_front,
          :others_label,
          :others_grouper,
        ].each{|m| api_method(m) }

        [
          :capped_key_accessor,
          :capped_value_accessor,
        ].each{|m| alias_method(m) }
      end

      def self.bubble_mixin
        color_mixin

        [
          :r,
          :elastic_radius,
          :radius_value_accessor,
          :sort_bubble_size,
          :min_radius,
          :min_radius_with_label,
          :max_bubble_relative_size,
          :exclude_elastic_zero,
        ].each{|m| api_method(m) }

        [
          :calculate_radius_domain,
          :r_min,
          :r_max,
          :bubble_r,
          :do_update_labels,
          :do_update_titles,
          :fade_deselected_area,
          :is_selected_node,
        ].each{|m| alias_method(m) }
      end

      base_mixin

      def to_n
        @native
      end

      def edit_url(id, params = {})
        "/crm/#{request.params[:schema]}/dashboard/#{request.params[:klass]}/charts/#{other_params[:id]}/edit"
      end

      def url_params
        filters
      end

    end

  end

end
