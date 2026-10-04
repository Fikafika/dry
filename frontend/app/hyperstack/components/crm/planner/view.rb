# backtick_javascript: true

class Crm
  class Planner
    class View < HyperComponent
      include ::Crm::Routes::Helpers
      include ::Crm::Planner::FullCalendarApi
      include ::Crm::Planner::ScrollHelpers
      include ::Crm::Planner::ConflictHelpers

      param :relation
      param :query, default: nil
      param :query_record, default: nil
      param :draggable_node_id, default: nil
      param :colors, default: {}
      param :reload, default: nil
      param :current_record_id, default: nil

      collect_other_params_as :other_params

      fires :view_changed
      fires :show_event
      fires :resource_added
      fires :resource_removed
      fires :event_dropped
      fires :color_changed
      fires :unschedule
      fires :filter_changed
      fires :settings_requested

      track_changes [:other_params, :last_date]

      track_changes [:current_record_id]

      RESOURCE_TIMELINE_BY_INTERVAL = {
        'day' => 'resourceTimelineDay',
        'week' => 'resourceTimelineWeek',
        'month' => 'resourceTimelineMonth',
        'year' => 'resourceTimelineYear'
      }.freeze

      RESOURCE_GRID_BY_INTERVAL = {
        'day' => 'timeGridDay',
        'week' => 'timeGridWeek',
        'month' => 'dayGridMonth',
        'year' => 'timelineYear'
      }.freeze

      VIEW_TYPES = ['agenda', 'gantt'].freeze

      MAX_COUNT_PER_RESOURCE = 300

      MAX_EVENT_COUNT = 300

      DEFAULT_SLOT_DURATION = '00:30:00'

      LANE_HEIGHT = '27px'

      CONTEXT_MENU_TYPES = {
        actions: 'actions',
        preview: 'preview',
        color: 'color',
      }.freeze

      before_mount do
        init_params
      end

      after_mount do
        init_view
        mutate # Needed in order to reload FullCalendar component
      end

      before_unmount do
        @calendar_draggable.JS.destroy
      end

      before_new_params do |next_props|
        if next_props[:reload] != reload
          @planner.JS.refetchEvents
          @planner.JS.refetchResources if @planner
        end
        @previous_current_record_id = current_record_id
      end

      after_new_params do
        assign_query_params
        update_resource_options_from_query
      end

      after_update do
        if other_params_last_date_changed? && @last_viewed_date.present?
          navigate_to_date(@last_viewed_date)
        end
        if current_record_id_changed?
          handle_highlight(current_record_id)
        end
      end

      def init_params
        @is_initialized = false
        @resource_options = []
        @planner_ref = `React.createRef()`
        assign_query_params
        @color_picker = {
          color: nil,
          resource_id: nil,
          color_circle: nil,
        }
        @datepicker_position = nil
        @context_menu = {
          type: nil,
          position: nil,
          data: {}
        }
        @conflict_state = Crm::Planner::ConflictState.new
        reset_conflict_state
      end

      def previous_current_record_id
        @previous_current_record_id
      end

      def assign_query_params
        @slot_min_time = other_params['min_day_time']
        @slot_max_time = other_params['max_day_time']
        @event_duration = other_params['event_duration']
        @slot_duration = other_params['slot_duration'] || DEFAULT_SLOT_DURATION
        @view_type = other_params['view_type']
        @interval = other_params['interval']
        @last_viewed_date = other_params['last_date']
      end

      def init_view
        return if @is_initialized
        @planner = `#{@planner_ref}.current.getApi()`
        init_draggable
        ::Element.find('.fc-footerResourceDropdown-button').add_class('p-0 bg-transparent border-0') # Hide footerResourceDropdown default button
        @is_initialized = true
      end

      def init_draggable
        draggable_node = `#{::Element.find("##{draggable_node_id}")}[0]`
        return unless draggable_node
        @calendar_draggable = `new FullCalendarDraggable(#{draggable_node}, #{draggable_props})`
      end

      def draggable_props
        {
          itemSelector: '.fc-event',
          eventData: Proc.new do |event_el|
            parsed_event_data = JSON.parse(event_el.JS[:dataset].JS[:event] || '{}')
            @existing_resource_ids = parsed_event_data['resourceIds']
            @current_drag_type = parsed_event_data['drag_type']
            {
              id: event_el.JS[:id],
              title: event_el.JS[:innerText],
              duration: @event_duration,
              resourceIds: @existing_resource_ids,
              # source: @planner.JS.getEventSourceById('db'), # FIXME not assigned to event
            }.to_n
          end
        }.to_n
      end

      render { content }

      def content
        Crm::Planner::ConflictToolbar(
          conflict_state: @conflict_state
        ).on(:navigate) do |direction|
          navigate_conflict(direction)
        end
        FullCalendar(full_calendar_options)
        if @is_initialized
          Portal(id: 'planner-dropdown-portal', parentSelector: '.fc-footerResourceDropdown-button') do
            resource_selector
          end
        end

        render_context_menu
        render_datepicker_context
      end

      def navigate_conflict(direction)
        new_index = (@current_conflict_index || 0) + direction
        return if new_index < 0 || new_index >= @sorted_conflict_ids.length
        @current_conflict_index = new_index
        event_id_to_focus = @sorted_conflict_ids[@current_conflict_index]
        scroll_to_event_location(event_id_to_focus, @view_type)
        @conflict_state.update(@sorted_conflict_ids, @current_conflict_index)
      end

      def resource_selector
        DIV(class: 'dropdown') do
          BUTTON(class: 'btn btn-primary dropdown-toggle', 'data-toggle': 'dropdown', 'aria-haspopup': 'true', 'aria-expanded': 'false') do
            I18n.t('crm.planner.view.resource')
          end
          UL(class: 'dropdown-menu') do
            @resource_options.each do |entry|
              next if query.dig('planner', 'resources')&.has_key?(entry[:name])
              LI(class: 'dropdown-item') do
                klass.human_attribute_name(entry[:name])
              end.on(:click) do
                resource_added!(entry[:name])
                @planner.JS.refetchResources
                mutate
              end
            end
          end
        end
      end

      def render_context_menu
        return unless @context_menu[:position]
        ContextMenu(
          position: @context_menu[:position],
          css_position: 'fixed'
        ) do
          case @context_menu[:type]
          when CONTEXT_MENU_TYPES[:actions]
            event_actions_menu
          when CONTEXT_MENU_TYPES[:preview]
            event_preview_menu
          when CONTEXT_MENU_TYPES[:color]
            color_picker_menu
          end
        end.on(:hidden) do
          reset_context_menu
        end
      end

      def event_actions_menu
        event = @context_menu[:data][:event]
        return unless event
        DIV do
          A(href: '#show_event', class: 'dropdown-item') do
            I(class: 'fas fa-search-plus fa-fw pr-4') {}
            I18n.t('crm.planner.action.show')
          end.on(:click) do
            show_event!(event.JS[:id])
            reset_context_menu
          end

          items_for_removing_resources

          A(href: '#unschedule', class: 'dropdown-item') do
            I(class: 'fas fa-calendar-minus fa-fw pr-4') {}
            I18n.t('crm.planner.action.unschedule')
          end.on(:click) do
            Modal.confirm(
              title: I18n.t('crm.planner.action.unschedule'),
              text: I18n.t('crm.planner.modal.unschedule_text')
            ) do
              resources_to_check = event.JS.getResources.to_a
              unschedule_event(event.JS[:id]).then do
                event.JS.remove
                detect_conflicts_by_resources(resources_to_check)
                @conflict_state.update(@sorted_conflict_ids, @current_conflict_index)
                reset_context_menu
                unschedule! # FIXME wait for indexation (check datatable)
              end.fail do
                reset_context_menu
              end
            end
          end

           A(href: '#unschedule_and_remove_resources', class: 'dropdown-item') do
            I(class: 'fas fa-calendar-times fa-fw pr-4') {}
            I18n.t('crm.planner.action.unschedule_and_remove_resources')
          end.on(:click) do
            Modal.confirm(
              title: I18n.t('crm.planner.action.unschedule_and_remove_resources'),
              text: I18n.t('crm.planner.modal.unschedule_and_remove_resources_text')
            ) do
              resources_params = {}
              event.JS.getResources.each do |r|
                next unless r.JS[:extendedProps]
                resource_name = params_key_for_resource(r)
                resources_params[resource_name] = if r.JS[:extendedProps].JS[:type] == 'HasMany'
                  []
                else
                  nil
                end
              end
              schedule_event(event.JS[:id], nil, nil, resources_params).then do
                event.JS.remove
                reset_context_menu
                unschedule!
              end.fail do
                reset_context_menu
              end
            end
          end
        end
      end

      def event_preview_menu
        event = @context_menu[:data][:event]
        return unless event
        EventPreview(
          event_id: event.JS[:id],
          klass: klass
        )
      end

      def show_context_menu(type, position, data = {})
        @context_menu = {
          type: type,
          position: position,
          data: data
        }
        mutate
      end

      def color_picker_menu
        data = @context_menu[:data]
        SketchPicker(
          color: data[:color]
        ).on(:changeComplete) do |color|
          color_changed!(data[:resource_id], color[:hex])
          colors[data[:resource_id]] = color[:hex]
          if data[:color_circle]
            `#{data[:color_circle]}.style.backgroundColor = #{color[:hex]}`
          end
          reset_context_menu
        end
      end

      def items_for_removing_resources
        resources = @event.JS.getResources
        resources.each do |r|
          next unless r.JS[:extendedProps]
          A(href: '#', class: 'dropdown-item') do
            I(class: 'fas fa-reply fa-fw pr-4') {}
            I18n.t('crm.planner.action.remove_resource', resource: r.JS[:title], type: r.JS[:extendedProps].JS[:category])
          end.on(:click) do
            resource_value = nil
            resource_name = params_key_for_resource(r)

            if r.JS[:extendedProps].JS[:type] == 'HasMany'
              resources_to_keep = resources.select do |r_|
                r_.JS[:extendedProps].JS[:category] == r.JS[:extendedProps].JS[:category] &&
                r_.JS[:id] != r.JS[:id]
              end
              resource_value = resources_to_keep.map {|r_| value_from_resource_id(r_.JS[:id])}
            end

            body = {
              base: {
                resource_name => resource_value
              }
            }
            removed_resource = r
            save_event(@event.JS[:id], body).then do
              all_resources_to_keep = resources.filter_map {|r_| r_.JS[:id] if r_.JS[:id] != r.JS[:id]}
              @event.JS.setResources(all_resources_to_keep)
              detect_conflicts_by_resources([removed_resource])
              reset_event_selection
            end
          end
        end
      end

      def reset_event_selection
        @event = nil
      end

      def reset_context_menu
        @context_menu = {
          type: nil,
          position: nil,
          data: {}
        }
        mutate
      end

      def update_resource_options_from_query
        @resource_options = []
        resource_config = query.dig('planner', 'resources') || {}

        klass.reflect_on_all_associations.each do |ref|
          next unless ref.options[:class_name].present?
          next if ref.options[:inverse_of].present?
          name = ref.name.to_s
          assoc_type = ref.class.name.demodulize.gsub('Reflection', '')

          @resource_options << {
            name: name,
            type: assoc_type,
            query: resource_config[name]&.deep_dup || {}
          }
        end

        klass.attributes.each do |k, v|
          next unless v['type'] == 'Enum'
          @resource_options << { name: k, type: 'enum' }
        end
      end

      def full_calendar_options
        {
          ref: @planner_ref,
          schedulerLicenseKey: ENV['FULLCALENDAR_LICENSE_KEY'],
          plugins: [`FullCalendarResourceTimeline`, `FullCalendarInteraction`, `FullCalendarList`, `FullCalendarTimegrid`, `FullCalendarDayGrid`, `bootstrapPlugin`],
          themeSystem: 'bootstrap',
          bootstrapFontAwesome: {
            prevCustom: 'fa-chevron-left',
            nextCustom: 'fa-chevron-right',
            datePickerCustom: 'fa-calendar-alt',
            settingsCustom: 'fa-cog',
          }.to_n,
          initialView: get_view(@view_type, @interval),
          initialDate: get_last_viewed_date,
          slotDuration: @slot_duration,
          editable: true,
          droppable: true,
          nowIndicator: true,
          resourceGroupField: 'category',
          height: 'calc(100vh - 80px)',
          resourceOrder: 'title',
          slotMinTime: @slot_min_time,
          slotMaxTime: @slot_max_time,
          resourceAreaWidth: '20%',
          locales: I18n.locale,
          firstDay: I18n.locale == 'fr' ? 1 : 0,
          customButtons: custom_buttons,
          eventSources: gather_event_sources,
          resources: gather_resources_proc,
          headerToolbar: {
            left: 'todayCustom,prevCustom,nextCustom,datePickerCustom',
            center: 'title',
            right: right_header_for_toolbar
          }.to_n,
          footerToolbar: {
            left: 'footerResourceDropdown'
          }.to_n,
          resourceLabelContent: resource_label_content_proc,
          resourceGroupLabelContent: resource_group_label_content_proc,
          eventReceive: event_receive_proc, # triggered when dropping external event
          eventDragStart: even_drag_start_proc,
          eventDrop: event_drop_proc,
          eventResize: event_resize_proc,
          eventClick: event_click_proc,
          eventMouseEnter: event_mouse_enter_proc,
          eventMouseLeave: event_mouse_leave_proc,
          eventContent: event_content_proc,
          eventDidMount: event_did_mount_proc,
          datesSet: dates_set_proc,
          resourceLabelDidMount: resource_label_did_mount_proc,
          resourceLaneDidMount: resource_lane_did_mount_proc,
        }
      end

      def event_mouse_enter_proc
        @event_mouse_enter_proc ||= Proc.new do |info|
          rect = info.JS[:el].JS.getBoundingClientRect
          position = {
            x: `#{rect}.right + 10`,
            y: `#{rect}.top`
          }
          show_context_menu(
            CONTEXT_MENU_TYPES[:preview],
            position,
            { event: info.JS[:event] }
          )
        end
      end

      def event_mouse_leave_proc
        @event_mouse_leave_proc ||= Proc.new do |info|
          if @context_menu[:type] == CONTEXT_MENU_TYPES[:preview]
            reset_context_menu
          end
        end
      end

      def custom_buttons
        result =  {
          todayCustom: {
            text: I18n.t('crm.planner.view.interval.today'),
            click: Proc.new do
              interval_for_today
            end
          },
          prevCustom: {
            click: Proc.new do
              previous_interval
            end
          },
          nextCustom: {
            click: Proc.new do
              next_interval
            end
          },
          datePickerCustom: {
            click: Proc.new do |mouse_event, el|
              rect = `#{el}.getBoundingClientRect()`
              @datepicker_position = {
                x: `#{rect}.left`,
                y: `#{rect}.bottom`
              }
              mutate
            end
          },
          settingsCustom: {
            text: '',
            click: Proc.new do
              settings_requested!
            end
          },
          footerResourceDropdown: {} # Will be replaced by dropdown portal
        }

        VIEW_TYPES.each do |view_type|
          result[:"#{view_type}Custom"] = {
            text: I18n.t("crm.planner.view.view_type.#{view_type}"),
            click: Proc.new do
              update_view(view_type, @interval)
              view_changed!(@interval, view_type)
            end
          }
        end

        RESOURCE_TIMELINE_BY_INTERVAL.each_key do |interval|
          result[:"#{interval}Custom"] = {
            text: I18n.t("crm.planner.view.interval.#{interval}"),
            click: Proc.new do
              update_view(@view_type, interval)
              view_changed!(interval, @view_type)
            end
          }
        end

        return result.to_n
      end

      def right_header_for_toolbar
        result = VIEW_TYPES.map do |view_type|
          "#{view_type}Custom"
        end.join(',')

        result += " "

        result += RESOURCE_TIMELINE_BY_INTERVAL.map do |interval, _|
          "#{interval}Custom"
        end.join(',')

        result += " settingsCustom"

        return result
      end

      def resource_label_content_proc
        @resource_label_content_proc ||= Proc.new do |arg|
          resource_id = arg.JS[:resource].JS[:id]
          prop_conflict = safe_extended_prop_bool(arg.JS[:resource], :has_conflict)
          store_conflict = @conflicting_resource_ids&.include?(resource_id.to_s)
          has_conflict = prop_conflict || store_conflict
          Crm::Planner::View::ResourceLabelContent(
            title: arg.JS[:resource].JS[:title],
            resource_id: resource_id,
            color: colors[resource_id],
            has_conflict: has_conflict,
          ).on(:color_picker_requested) do |params|
            @color_picker = {
              resource_id: resource_id,
              color: params[:color],
              color_circle: params[:color_circle]
            }
            @color_picker_position = { x: params[:mouse_x], y: params[:mouse_y] }
            show_context_menu(
              CONTEXT_MENU_TYPES[:color],
              { x: params[:mouse_x], y: params[:mouse_y] },
              {
                resource_id: resource_id,
                color: params[:color],
                color_circle: params[:color_circle]
              }
            )
            mutate
          end
        end
      end

      def render_datepicker_context
        return unless @is_initialized && @datepicker_position
        ContextDatePicker(
          position: @datepicker_position,
          css_position: 'fixed',
          z_index: 0,
          css_class: 'border-0 bg-transparent',
          initial_date: @planner.JS.formatIso(current_date(), {omitTime: true}),
        ).on(:date_selected) do |selected_date|
          navigate_to_date(selected_date)
          mutate
        end.on(:hidden) do
          @datepicker_position = nil
          mutate
        end
      end

      def resource_group_label_content_proc
        @resource_group_label_content_proc ||= Proc.new do |arg|
          group_name = arg.JS[:groupValue]
          resource_klass = resource_class_from_name(group_name)
          name_attribute = resource_klass&.name_attribute
          DIV(class: 'justify-content-between align-items-center float-right mr-4') do
            DIV(class:"d-inline-flex w-100 justify-content-between") do
              SPAN(class: 'fc-datagrid-cell-main') do
                group_name
              end
              SPAN do
                I(class: 'fc-group-delete fa-solid fa-times text-secondary cursor-pointer pr-2').on(:click) do
                  @planner.JS.getResources.each do |r|
                    r.JS.remove if r.JS[:extendedProps].JS[:category] == arg.JS[:groupValue]
                  end
                  resource_removed!(arg.JS[:groupValue])
                  mutate
                end
              end
            end
            Crm::Planner::SearchWithFilters(
              default_value: query.dig('planner', 'resources', group_name, 'filters', name_attribute, 'contains') || '',
              filter_present: resource_filter_present?(group_name),
              modal_target: "#resource_filters_dialog_#{group_name}",
            ).on(:search_changed) do |search_text|
              filter_changed!(group_name, search_text)
              @planner.JS.refetchResources if @planner
            end
          end
        end
      end

      def resource_filter_present?(group_name)
        filters = query.dig('planner', 'resources', group_name, 'filters')
        filters.present? && filters.any?
      end

      def resource_class_from_name(resource_name)
        reflection = klass.reflect_on_association(resource_name.to_sym)
        reflection.options['class_name'].safe_constantize if reflection
      end

      def event_receive_proc
        @event_receive_proc ||= Proc.new do |info|
          handle_external_drop(info)
        end
      end

      def even_drag_start_proc
        @even_drag_start_proc ||= Proc.new do |info|
          handle_event_drag_start(info)
        end
      end

      def event_drop_proc
        @event_drop_proc ||= Proc.new do |info|
          handle_event_drop(info)
        end
      end

      def event_resize_proc
        @event_resize_proc ||= Proc.new do |info|
          evt = info.JS[:event]
          schedule_event(evt.JS[:id], evt.JS[:start], evt.JS[:end]).fail do
            info.JS.revert
          end
        end
      end

      def event_click_proc
        @event_click_proc ||= Proc.new do |info|
          event = info.JS[:jsEvent]
          event.JS.stopPropagation
          event.JS.preventDefault
          if @context_menu[:type] == CONTEXT_MENU_TYPES[:preview]
            @context_menu[:type] = CONTEXT_MENU_TYPES[:actions]
            @context_menu[:position] = {x: event.JS[:pageX], y: event.JS[:pageY]}
            @context_menu[:data] = { event: info.JS[:event] }
          else
            show_context_menu(
              CONTEXT_MENU_TYPES[:actions],
              {x: event.JS[:pageX], y: event.JS[:pageY]},
              { event: info.JS[:event] }
            )
          end
          @event = info.JS[:event]
          mutate
        end
      end

      def event_content_proc
        @event_content_proc ||= Proc.new do |info|
          if is_a_indisponibility_event?(info) # TODO || current resource type != 'HasMany'
            display_event_title(info)
          else
            display_event_with_drag(info)
          end
        end
      end

      def display_event_with_drag(info)
        event_js = info.JS[:event]
        is_conflicting = event_js.JS[:extendedProps].JS[:is_conflicting]
        DIV(class: 'position-relative rounded col-12 cursor-grab', style: { userSelect: 'none' }, draggable: true) do
          if is_conflicting
            Crm::Planner::ConflictBadge(css_classes: 'text-danger', style: { padding: '1px 3px', backgroundColor: 'rgba(255,255,255,1)', borderRadius: '50%', fontSize: '10px',})
          end
          display_event_title(info)
          DIV(class: 'container') do
            DIV(
              class: 'position-absolute h-100 col-6', style: {top: 0, left: 0, zIndex: 1030},
              title: I18n.t('crm.planner.modal.replace_btn_text'), 'data-toggle': 'tooltip'
            ).on(:mouse_enter) do |e|
              @current_drag_type = 'replace'
            end
            DIV(id: 'middle-line', class: 'position-absolute d-none bg-light', style: {top: 0, bottom: 0, left: '50%', width: '2px', zIndex: 1020})
            DIV(
              class: 'position-absolute h-100 col-6', style: {top: 0, left: '50%', zIndex: 1030},
              title: I18n.t('crm.planner.modal.add_btn_text'), 'data-toggle': 'tooltip'
            ).on(:mouse_enter) do |e|
              @current_drag_type = 'add'
            end
          end.on(:mouse_enter) do |evt|
            element = ::Element.find(evt.current_target.to_n).children('#middle-line').first
            element.remove_class('d-none') if element
          end.on(:mouse_leave) do |evt|
            element = ::Element.find(evt.current_target.to_n).children('#middle-line').first
            element.add_class('d-none') if element
          end
        end
      end

      def display_event_title(info)
        DIV(class: 'position-relative text-truncate', style: { zIndex: 3, pointerEvents: 'none'}) do
          info.JS[:event].JS[:title]
        end
      end

      def dates_set_proc
        @dates_set_proc ||= Proc.new do |info|
          current_date = info.JS[:view].JS[:currentStart]
          if current_date
            date_string = @planner.JS.formatIso(current_date, {omitTime: true}) if @planner
            if date_string
              view_changed!(@interval, @view_type, date_string)
            end
          end
        end
      end

      def get_last_viewed_date
        date_param = query&.dig('planner', 'last_date')
        return date_param if date_param.is_a?(String) && date_param.match?(/^\d{4}-\d{2}-\d{2}$/)
        Date.today.strftime('%Y-%m-%d')
      end

      def handle_highlight
        return unless @is_initialized
        make_event_highlight(previous_current_record_id, 'none') if previous_current_record_id
        make_event_highlight(current_record_id, '0 0 10px 3px rgba(255, 215, 0, 0.8)') if current_record_id
      end

      def make_event_highlight(event_id, shadow_value)
        event = ::Element.find("[data-event-id='#{event_id}']")
        return unless event
        event.css(boxShadow: shadow_value)
      end

      def event_did_mount_proc
        @event_did_mount_proc ||= Proc.new do |info|
          timeline_container = info.JS[:el].JS.closest('.fc-timeline-events')
          timeline_container.JS[:style].JS[:padding] = '0' if timeline_container
          info.JS[:el].JS.setAttribute('data-event-id', info.JS[:event].JS[:id])
          unless is_a_indisponibility_event?(info)
            colors = info.JS[:event].JS[:extendedProps].JS[:colors]
            if colors
              info.JS[:el].JS[:style].JS[:backgroundImage] = "linear-gradient(to right, #{colors})"
            end
          end
          info.JS[:el].JS[:dataset].JS[:eventId] = info.JS[:event].JS[:id]
          is_current = current_record_id && info.JS[:event].JS[:id].to_s == current_record_id.to_s
          if is_current
            info.JS[:el].JS[:style].JS[:boxShadow] = '0 0 10px 3px rgba(255, 215, 0, 0.8)'
          end
        end
      end

      def resource_label_did_mount_proc
        @resource_label_did_mount_proc ||= Proc.new do |el|
          element = ::Element[`#{el}.el`]
          resource = `#{el}.resource`
          resource_id = `#{resource} && #{resource}.id != null ? String(#{resource}.id) : null`
          if resource_id
            element.attr('data-resource-id', resource_id.to_s)
          end
          frame = element.find('.fc-datagrid-cell-frame')
          frame.css(height: LANE_HEIGHT) if frame
          cushion = element.find('.fc-datagrid-cell-cushion')
          cushion.css(padding: '0') if cushion
        end
      end

      def resource_lane_did_mount_proc
        @resource_lane_did_mount_proc ||= Proc.new do |el|
          element = ::Element[`#{el}.el`]
          frame = element.find('.fc-timeline-lane-frame')
          frame.css(height: LANE_HEIGHT) if frame
        end
      end

      def is_a_indisponibility_event?(info)
        !info.JS[:isDraggable]
      end

      def gather_event_sources
        @event_sources ||= [
          {
            id: 'db',
            events: Proc.new do |info, successCallback, failureCallback|
              unless @fetching_events
                @fetching_events = true
                fetch_events(info, successCallback, failureCallback)
              end
            end
          }.to_n,
        ].to_n
      end

      def gather_resources_proc
        @resources_proc ||= Proc.new do |info, successCallback, failureCallback|
          fetch_resources(info, successCallback, failureCallback)
        end
      end

      def is_a_indisponibility_event?(info)
        !info.JS[:isDraggable]
      end

      def fetch_events(info, successCallback, errorCallback)
        filters = search_filter_for_events(info.JS[:startStr], info.JS[:endStr])
        query_dup = query.params.deep_dup

        query_dup['table'] ||= {}

        if query_dup.dig('table', 'filters')
          query_dup['table']['filters'] = Crm::Filters::AdvancedList.merge(query_dup.dig('table', 'filters'), filters)
        else
          query_dup['table']['filters'] = filters
        end

        klass.update_cache([:all])
        query_relation = klass.where_filters(query_dup['table']['filters']).includes(includes_for_event).per(MAX_EVENT_COUNT)
        promise = query_relation.all.__promise__
        promise.then do
          query_relation.all do |events|
            evts = []
            events.each do |evt|
              evt_params = convert_to_fullcalendar_event(evt)
              evt_params.merge!(additional_props_for_event(evt))
              evts << evt_params
            end
            detect_conflicts_in_data(evts)
            update_resources_conflict_state
            @conflict_state.update(@sorted_conflict_ids, @current_conflict_index)
            `#{successCallback}(#{evts.to_n})`
            mutate
          end
          @fetching_events = false
        end.fail do
          @fetching_events = false
          `#{errorCallback}(#{I18n.t('shared.error') + ' ' + I18n.t('shared.error_messages')})` # Will log to console
        end
        return promise
      end

      def update_resources_conflict_state
        return unless @planner
        @planner.JS.getResources.each do |resource|
          resource_id = resource.JS[:id]
          next unless resource_id
          should_have_conflict = @conflicting_resource_ids.include?(resource_id.to_s)
          current_state = safe_extended_prop_bool(resource, :has_conflict)
          if current_state != should_have_conflict
            resource.JS.setExtendedProp('has_conflict', should_have_conflict)
          end
        end
      end

      def additional_props_for_event(event)
        result = {classNames: ['rounded', 'rounded-lg']}
        evt_resource_ids = []
        evt_colors = []

        @resource_options.each do |opt|
          value = event.send(opt[:name])
          next if value.blank?
          color_key = opt[:name] + '-'

          case opt['type']
          when 'enum'
            color_key += value
            evt_colors << colors[color_key] if colors.has_key?(color_key)
            evt_resource_ids << generate_resource_id(opt[:name], value)
          when 'BelongsTo'
            color_key += value.id
            evt_colors << colors[color_key] if colors.has_key?(color_key)
            evt_resource_ids << generate_resource_id(opt[:name], value.id)
          when 'HasMany'
            value.each do |v|
              color_key_ = color_key + v.id
              evt_colors << colors[color_key_] if colors.has_key?(color_key_)
              evt_resource_ids << generate_resource_id(opt[:name], v.id)
            end
          end
        end

        result.merge!(classNames: ['rounded', 'rounded-lg'], resourceIds: evt_resource_ids)

        if evt_colors.any?
          evt_colors.uniq!
          result.merge!(colors_for_event(evt_colors))
        end

        return result
      end

      def colors_for_event(evt_colors)
        result = {borderColor: evt_colors.first}

        if evt_colors.length == 1
          result[:backgroundColor] = evt_colors.first
        elsif evt_colors.length > 1
          result[:extendedProps] ||= {}
          result[:extendedProps][:colors] = evt_colors.join(', ')
        end

        return result
      end

      def search_filter_for_events(start_date, end_date)
        {
          start_date_attribute => {
            'after' => start_date || view_start_date
          },
          end_date_attribute => {
            'before' => end_date || view_end_date
          }
        }
      end

      def includes_for_event
        includes = {}

        @resource_options.each do |entry|
          next unless entry[:type] == 'BelongsTo' || entry[:type] == 'HasMany'
          next unless query.dig('planner', 'resources')&.has_key?(entry[:name])
          includes[entry[:name]] = 1
        end

        return includes
      end

      def convert_to_fullcalendar_event(event_record)
        {
          id: event_record.id,
          title: event_record.try(name_attribute_for_klass) || DEFAULT_EVENT_NAME,
          start: event_record.send(start_date_attribute),
          end: event_record.send(end_date_attribute),
        }
      end

      def fetch_resources(info, successCallback, errorCallback)
        resources = []
        promises = []
        update_resource_options_from_query
        used_resources = query.dig('planner', 'resources')&.keys || []

        @resource_options.each do |opt|
          next unless used_resources.include?(opt[:name])

          case opt[:type]
          when :enum
            klass.send(opt[:name].pluralize).each do |e|
              resources << {
                id: generate_resource_id(opt[:name], e),
                category: opt[:name],
                type: opt[:type],
                title: klass.human_attribute_value(opt[:name], e)
              }
            end
          when :BelongsTo, :HasMany
            reflection = klass.reflect_on_association(opt[:name].to_sym)
            association_klass = reflection.options['class_name'].safe_constantize

            next unless association_klass

            scope = association_klass
            filters = opt.dig(:query, 'filters')
            scope = scope.where_filters(filters) if filters.present?
            indispo_assoc_name = indisponibility_association_name(reflection.klass)
            scope = scope.includes(indispo_assoc_name => 1) if indispo_assoc_name.present?
            query_relation = scope.per(MAX_COUNT_PER_RESOURCE).all

            promises << query_relation.__promise__.then do
              query_relation.each do |r|
                resource_id = generate_resource_id(opt[:name], r.id)
                resources << {
                  id: resource_id,
                  category: opt[:name],
                  type: opt[:type],
                  title: r.try(association_klass.name_attribute) || DEFAULT_EVENT_NAME
                }
                indisponibilities = r.try(indispo_assoc_name)
                add_indiponibility_events(indisponibilities, resource_id)
              end
            end
          end
        end

        Promise.when(*promises).then do |args|
          resources.sort_by! {|r| r['category']}
          `#{successCallback}(#{resources.to_n})`
        end.fail do
          `#{errorCallback}(#{I18n.t('shared.error') + ' ' + I18n.t('shared.error_messages')})`
        end
      end

      def generate_resource_id(resource_name, id)
        "#{resource_name}-#{id}"
      end

      def retrieve_resource_name(resource_id)
        resource_id.gsub(/\A.+?-/, '')
      end

      def add_indiponibility_events(indisponibilites, resource_id)
        return unless indisponibilites&.any?

        indisponibilites.each do |indispo|
          start_date = indispo.try(start_date_attribute)
          end_date = indispo.try(end_date_attribute)

          next if start_date.blank? || end_date.blank?
          add_event(
            start: start_date,
            end: end_date,
            title: indispo.try(indispo.class.name_attribute) || DEFAULT_EVENT_NAME,
            display: 'background',
            overlap: false,
            resourceIds: [resource_id],
            classNames: ['fc-indispo', 'bg-dark-yiq', 'text-white'],
          )
        end
      end

      def save_event(id, body)
        path = "#{klass.api_path}/#{id}.json"
        promise = ::HTTP.patch(path, payload: body)
        return promise
      end

      def schedule_event(id, start_date, end_date, params = {})
        body = {
          base: {
            start_date_attribute => start_date,
            end_date_attribute => end_date,
          }
        }
        body[:base].merge!(params) if params.present?
        save_event(id, body)
      end

      def unschedule_event(id)
        schedule_event(id, nil, nil)
      end

      def start_date_attribute
        klass.try(:event_start_date_name)
      end

      def end_date_attribute
        klass.try(:event_end_date_name)
      end

      def indisponibility_association_name(assoc_klass)
        assoc_klass.try(:event_indisponibility_association_name)
      end

      def klass
        if relation.is_a?(HyperResource::Relation)
          relation.klass
        else
          relation
        end
      end

      def name_attribute_for_klass
        klass.name_attribute
      end

      def update_view(view_type, interval)
        new_view = get_view(view_type, interval)
        change_view(new_view)
        @view_type = view_type
        @interval = interval
      end

      def get_view(view_type, interval)
        case view_type
        when 'gantt'
          RESOURCE_TIMELINE_BY_INTERVAL[interval] || RESOURCE_TIMELINE_BY_INTERVAL['day']
        else
          RESOURCE_GRID_BY_INTERVAL[interval] || RESOURCE_GRID_BY_INTERVAL['day']
        end
      end

      def handle_external_drop(info)
        event = info.JS[:event]
        unless event
          info.JS.revert
          return
        end

        resources_from_event = event.JS.getResources
        unless resources_from_event.any?
          info.JS.revert
          return
        end
        body = {
          base: {
            start_date_attribute => event.JS[:start],
            end_date_attribute => event.JS[:end]
          }
        }

        if @current_drag_type == 'replace'
          safe_existing_ids = @existing_resource_ids || []
          new_resource = resources_from_event.detect { |r| !safe_existing_ids.include?(r.JS[:id]) }
          if new_resource
            body[:base].merge!(resource_request_params(new_resource))
          end
        elsif @current_drag_type == 'add'
          resources_from_event.each do |r|
            attr_key = params_key_for_resource(r)
            body[:base][attr_key] ||= []
            body[:base][attr_key] << value_from_resource_id(r.JS[:id])
          end
          body[:base].each do |k, v|
            v.uniq! if v.is_a?(Array)
          end
        end

        @existing_resource_ids = nil

        save_event(info.JS[:event].JS[:id], body).then do
          event_dropped!(info.JS[:draggedEl])
          detect_conflicts_by_resources(resources_from_event)
          @conflict_state.update(@sorted_conflict_ids, @current_conflict_index)
        end.fail do
          info.JS.revert
        end
      end

      def params_key_for_resource(resource)
        props = resource.JS[:extendedProps]
        resource_name = props.JS[:category]

        case props.JS[:type]
        when 'HasMany'
          "#{resource_name.singularize}_ids"
        when 'BelongsTo'
          "#{resource_name.singularize}_id"
        when 'enum'
          resource_name
        else
          ''
        end
      end

      def resource_request_params(resource)
        param_key = params_key_for_resource(resource)
        base_value = value_from_resource_id(resource.JS[:id])
        param_value = resource.JS[:extendedProps].JS[:type] == 'HasMany' ? [base_value] : base_value
        return {param_key => param_value}
      end

      def value_from_resource_id(resource_id)
        resource_id.gsub(/\A.+?-/, '') # match any characters until first - (included)
      end

      def handle_event_drag_start(info)
        event = info.JS[:event]

        original_resources = []
        event.JS.getResources.each do |r|
          next unless r
          original_resources << {
            type: r.JS[:extendedProps].JS[:type],
            category: r.JS[:extendedProps].JS[:category],
            id: value_from_resource_id(r.JS[:id])
          }
        end
        @previous_resources = original_resources
      end

      def handle_event_drop(info)
        event = info.JS[:event]
        impacted_resources = []
        if event.JS.getResources
          event.JS.getResources.each { |r| impacted_resources << r }
        end
        impacted_resources << info.JS[:oldResource] if info.JS[:oldResource]
        body = {
          base: {
            start_date_attribute => event.JS[:start],
            end_date_attribute => event.JS[:end],
          }
        }

        if info.JS[:newResource]
          add_resource_params(info, body[:base])

          new_resource_props = info.JS[:newResource].JS[:extendedProps]
          old_resource_props = info.JS[:oldResource].JS[:extendedProps]
          same_has_many_type = new_resource_props.JS[:type] == 'HasMany' && new_resource_props.JS[:type] == old_resource_props.JS[:type]
          same_category = new_resource_props.JS[:type] == old_resource_props.JS[:type]

          unless same_has_many_type && same_category && @current_drag_type == 'replace'
            resource_ids = event.JS.getResources.map {|e| e.JS[:id]}
            resource_ids << info.JS[:oldResource].JS[:id] if info.JS[:oldResource]
            event.JS.setResources(resource_ids)
          end
        end

        save_event(event.JS[:id], body).then do
          detect_conflicts_by_resources(impacted_resources)
          @conflict_state.update(@sorted_conflict_ids, @current_conflict_index)
          @current_drag_type = nil
          @previous_resources = nil
        end.fail do
          @current_drag_type = nil
          @previous_resources = nil
          info.JS.revert
        end
      end

      def add_resource_params(info, base_params)
        new_resource = info.JS[:newResource]
        resource_type = new_resource.JS[:extendedProps].JS[:type]

        if @current_drag_type && resource_type != 'enum'
          invalidation_proc = nil

          if @current_drag_type == 'replace'
            old_resource = info.JS[:oldResource]
            old_resource_props = old_resource.JS[:extendedProps]
            old_resource_id = value_from_resource_id(old_resource.JS[:id])
            invalidation_proc = Proc.new do |res|
              res[:type] == old_resource_props.JS[:type] && res[:category] == old_resource_props.JS[:category] && res[:id] != old_resource_id
            end
          elsif @current_drag_type == 'add'
            invalidation_proc = Proc.new do |res|
              res[:type] == 'HasMany' && res[:category] == new_resource.JS[:extendedProps].JS[:category]
            end
          end

          attr_key = params_key_for_resource(new_resource)
          new_resource_id = value_from_resource_id(new_resource.JS[:id])
          resources_for_update = gather_resource_ids(new_resource_id, &invalidation_proc)
          resources_for_update = resources_for_update.first if resource_type == 'BelongsTo'
          base_params[attr_key] = resources_for_update
        else
          base_params.merge!(resource_request_params(new_resource))
        end
      end

      def gather_resource_ids(new_resource_id, &block)
        kept_ids = [new_resource_id]

        @previous_resources&.each do |res|
          next if res[:id] == new_resource_id
          next unless yield(res)
          kept_ids << res[:id]
        end

        return kept_ids
      end
    end
  end
end