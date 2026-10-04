# backtick_javascript: true

class Crm
  class Planner
    module ConflictHelpers

      def safe_extended_prop(js_object, prop_name)
        extended_props = js_object.JS[:extendedProps]
        return nil if `#{extended_props} == null || #{extended_props} === undefined`
        value = extended_props.JS[prop_name]
        return nil if `#{value} === undefined`
        value
      end

      def safe_extended_prop_bool(js_object, prop_name)
        value = safe_extended_prop(js_object, prop_name)
        `#{value} === true`
      end

      def detect_conflicts_generic(collection, extractor:, marker:, scoped_resource_ids: nil)
        reset_conflict_state(scoped_resource_ids)
        events_by_resource = Hash.new { |h, k| h[k] = [] }
        if collection && collection.any?
          collection.each do |item|
            data = extractor.call(item)
            next unless data
            marker.call(item, false)
            data[:resource_ids].each do |res_id|
              events_by_resource[res_id.to_s] << {
                item: item,
                data: data,
              }
            end
          end
        end
        resources_to_process = scoped_resource_ids || events_by_resource.keys
        resources_to_process.each do |res_id|
          res_id = res_id.to_s
          entries = events_by_resource[res_id] || []
          entries.sort_by! { |e| e[:data][:start] }
          if entries.length >= 2
            entries.each_with_index do |entry_i, i|
              ((i + 1)...entries.length).each do |j|
                entry_j = entries[j]
                break if entry_j[:data][:start] >= entry_i[:data][:end]
                marker.call(entry_i[:item], true)
                marker.call(entry_j[:item], true)
                register_conflict(
                  res_id,
                  { id: entry_i[:data][:id], start: entry_i[:data][:start] },
                  { id: entry_j[:data][:id], start: entry_j[:data][:start] }
                )
              end
            end
          end
          update_resource_conflict_flag(res_id, entries)
        end

        finalize_conflict_detection
      end

      def detect_conflicts_in_data(events_hashes)
        detect_conflicts_generic(
          events_hashes,
          extractor: method(:extract_from_hash),
          marker: method(:mark_hash_conflict)
        )
      end

      def detect_conflicts_by_resources(resources)
        return unless resources&.any? && @planner
        unique_resources = resources.uniq { |r| r.JS[:id] }
        resource_ids_scope = unique_resources.map { |r| r.JS[:id].to_s }
        all_events = unique_resources.flat_map do |resource|
          resource.JS.setExtendedProp('has_conflict', false)
          resource.JS.getEvents.to_a
        end.uniq { |e| e.JS[:id] }
        detect_conflicts_generic(
          all_events,
          extractor: method(:extract_from_js_event),
          marker: method(:mark_js_event_conflict),
          scoped_resource_ids: resource_ids_scope
        )
      end


      private


      def extract_from_hash(item)
        return nil unless item[:start] && item[:end] && item[:resourceIds]
        {
          id: item[:id],
          start: Time.parse(item[:start]).to_f * 1000,
          end: Time.parse(item[:end]).to_f * 1000,
          resource_ids: item[:resourceIds]
        }
      end

      def mark_hash_conflict(item, is_conflicting)
        item[:extendedProps] ||= {}
        item[:extendedProps][:is_conflicting] = is_conflicting
      end

      def extract_from_js_event(js_event)
        start_date = js_event.JS[:start]
        end_date = js_event.JS[:end]
        return nil unless start_date && end_date
        resources = js_event.JS.getResources
        return nil unless resources
        {
          id: js_event.JS[:id],
          start: start_date.JS.getTime(),
          end: end_date.JS.getTime(),
          resource_ids: resources.map { |r| r.JS[:id] }
        }
      end

      def mark_js_event_conflict(js_event, is_conflicting)
        js_event.JS.setExtendedProp('is_conflicting', is_conflicting)
      end

      def update_resource_conflict_flag(res_id, entries)
        return unless @planner
        has_conflict = entries.any? do |entry|
          item = entry[:item] || entry['item']
          next false unless item
          if Hash === item
             props = item[:extendedProps] || item['extendedProps']
             props && (props[:is_conflicting] || props['is_conflicting'])
          else
             safe_extended_prop_bool(item, 'is_conflicting')
          end
        end
        resource = @planner.JS.getResourceById(res_id)
        if resource
          current_state = safe_extended_prop_bool(resource, 'has_conflict')
          if current_state != has_conflict
            resource.JS.setExtendedProp('has_conflict', has_conflict)
          end
        end
      end

      def reset_conflict_state(resource_ids = nil)
        if resource_ids
          @conflicting_resource_ids ||= Set.new
          @conflicting_resource_ids.subtract(resource_ids)
          @conflicts_by_resource_id ||= {}
          resource_ids.each { |id| @conflicts_by_resource_id.delete(id) }
        else
          @conflicting_resource_ids = Set.new
          @conflicts_by_resource_id = {}
        end
        @sorted_conflict_ids = []
        @current_conflict_index = nil
      end

      def register_conflict(res_id, evt_a, evt_b)
        (@conflicting_resource_ids ||= Set.new).add(res_id)
        ((@conflicts_by_resource_id ||= {})[res_id] ||= []).push(
          { id: evt_a[:id], start: evt_a[:start] },
          { id: evt_b[:id], start: evt_b[:start] }
        )
      end

      def finalize_conflict_detection
        unique_resource_events = []
        if @conflicts_by_resource_id
          @conflicts_by_resource_id.each do |res_id, events|
            clean_events = events&.compact&.select do |e|
              e.is_a?(Hash) && e[:start]
            end
            next unless clean_events && clean_events.any?
            first_event = clean_events.min_by { |e| e[:start].to_i }
            unique_resource_events << first_event if first_event
          end
        end
        if unique_resource_events.any?
          @sorted_conflict_ids = unique_resource_events.sort_by { |e| e[:start].to_i }.map { |e| e[:id] }
          @current_conflict_index = 0
        else
          @sorted_conflict_ids = []
          @current_conflict_index = nil
        end
      end
    end
  end
end