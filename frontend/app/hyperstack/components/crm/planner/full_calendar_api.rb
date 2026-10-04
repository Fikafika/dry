class Crm
  class Planner
    module FullCalendarApi

      def for_each_event
        @planner.JS.getEvents.each do |evt|
          yield evt
        end
      end

      def for_each_resource_from_event(native_event)
        native_event.JS.getResources.each do |res|
          yield res
        end
      end

      def add_event(params)
        @planner.JS.addEvent(params.to_n)
      end

      def add_resource(params, scroll_to_resource = false)
        @planner.JS.addResource(params, scroll_to_resource)
      end

      def remove_event(id)
        evt = @planner.JS.getEventById(id)
        evt.JS.remove if evt
      end

      def get_event(id)
        @planner.JS.getEventById(id)
      end

      def change_view(type)
        @planner.JS.changeView(type)
      end

      def refetch_resources
        @planner.JS.refetchResources
      end

      def interval_for_today
        @planner.JS.today()
      end

      def next_interval
        @planner.JS.next()
      end

      def previous_interval
        @planner.JS.prev()
      end

      def navigate_to_date(date_string)
        @planner.JS.gotoDate(date_string)
      end

      def current_date
        @planner.JS.getDate
      end

      def view_start_date
        to_iso8601(@planner.JS.view.JS.activeStart)
      end

      def view_end_date
        to_iso8601(@planner.JS.view.JS.activeEnd)
      end

      private

      def to_iso8601(date)
        @planner.JS.formatIso(date)
      end

    end
  end
end