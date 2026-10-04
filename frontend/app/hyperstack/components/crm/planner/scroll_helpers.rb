# backtick_javascript: true

class Crm
  class Planner
    module ScrollHelpers

      def scroll_to_event_location(event_id, view_type)
        fc_event = @planner.JS.getEventById(event_id)
        return unless fc_event
        @planner.JS.gotoDate(fc_event.JS[:start])
        after(0.1) do
          case view_type
          when 'gantt'
            resource_id = find_target_resource_id_for_event(event_id)
            scroll_gantt_view(event_id, resource_id)
          else
            scroll_agenda_view(event_id, fc_event)
          end
        end
      end


      private


      def find_target_resource_id_for_event(event_id)
        fc_event = @planner.JS.getEventById(event_id)
        return nil unless fc_event
        resources = fc_event.JS.getResources
        return nil unless resources && resources.JS[:length].to_i > 0
        res_ids = resources.JS.map { |r| r.JS[:id].to_s }
        target = res_ids.find { |id| @conflicting_resource_ids&.include?(id) } || res_ids.first
        target
      end

      def scroll_gantt_view(event_id, resource_id)
        return unless resource_id
        scroll_datagrid_to_resource(resource_id)
        scroll_timeline_to_event(event_id, resource_id)
      end

      def scroll_agenda_view(event_id, fc_event = nil)
        fc_event ||= @planner.JS.getEventById(event_id)
        return unless fc_event
        start_date = fc_event.JS[:start]
        if start_date
           time_str = `#{start_date}.toTimeString().split(' ')[0]`
           @planner.JS.scrollToTime(time_str)
        end
        after(0.1) do
          element = ::Element.find(".fc-event[data-event-id='#{event_id}']").first
          scroll_element_into_view(element) if element
        end
      end

      def scroll_datagrid_to_resource(target_resource_id)
        resource_label = ::Element.find(".fc-datagrid-cell[data-resource-id='#{target_resource_id}']").first
        return unless resource_label
        datagrid_body = resource_label.closest('.fc-datagrid-body')
        scroll_element_center_container(resource_label, datagrid_body) if datagrid_body
      end

      def scroll_timeline_to_event(event_id, target_resource_id)
        selector = ".fc-event[data-event-id='#{event_id}']"
        target_event_el = nil
        ::Element.find(selector).each do |el|
          closest_resource = el.closest('[data-resource-id]')
          if closest_resource && closest_resource.attr('data-resource-id').to_s == target_resource_id.to_s
            target_event_el = el
            break
          end
        end
        target_event_el ||= ::Element.find(selector).first
        scroll_element_into_view(target_event_el) if target_event_el
      end

      def scroll_element_center_container(target, container)
        `
          var t = #{target.to_n}[0];
          var c = #{container.to_n}[0];
          if (t && c) {
            var top = t.offsetTop;
            var cH = c.offsetHeight;
            var tH = t.offsetHeight;
            c.scrollTo({ top: top - (cH / 2) + (tH / 2), behavior: 'smooth' });
          }
        `
      end

      def scroll_element_into_view(element)
        `
          var el = #{element.to_n}[0];
          if (el && el.scrollIntoView) {
            el.scrollIntoView({ behavior: 'smooth', block: 'center', inline: 'center' });
          }
        `
      end
    end
  end
end