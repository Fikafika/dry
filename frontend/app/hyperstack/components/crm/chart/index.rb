require 'components/crm/chart/registry'
require 'components/crm/index'

class Crm
  module Chart
    class Index < ::Crm::Index::Base
      include Chart::Registry

      before_mount do
        @mode = "chart"
      end

      render do
        if record && !record.loading? && dashboard_record && !dashboard_record.loading?
          DIV(class: "#{height_class}", style: {margin: chart_margins}) do # TODO: 0 marg for table
            Chart.create_element(record.attributes.merge(uuid: "#{record.id}", registry: self, groups: record.groups))
          end
        end
      end

      def global_toolbar_left
        Portal(id: 'global-toolbar-left') do
          Link(dashboard_url, class: "btn btn-transparent-primary") do
            I(class: 'pr-2 fa fa-chevron-left fa-fw')
            SPAN do
              I18n.t("shared.back")
            end
          end
        end
      end

      def chart_margins
        record.type == "Table" ? 0 : "4% 2%"
      end

      def height_class
        record.type == "Table" ? "h-100" : "h-75"
      end

      def init

        if query_path_changed? || action_changed?
          @record = nil
          @record_klass = nil
          @previous_klass = klass
          @previous_record_updated_at = nil

          @draw_count ||= 0
          @draw_count += 1
        end

        super
      end

      def chart_records
        return [] unless record && record.loaded?
        return [record] # TODO dashboard.charts ?
      end

      def record
        return unless User.current
        return observe @record if @record
        return unless record_klass
        @record = record_klass.with_includes_for_load.find(request.params[:id])
        return observe @record if @record
      end

      def record_klass
        @record_klass ||= "#{klass.parent.name}::R::Chart::Base".safe_constantize
      end

      def dashboard_record
        return unless User.current
        return observe @dashboard if @dashboard
        return unless dashboard_klass && dashboard_id
        observe @dashboard ||= dashboard_klass.with_includes_for_load.find(dashboard_id)
      end

      def dashboard_id
        request.params[:dashboard_id]
      end

      def dashboard_klass
        @dashboard_klass ||= "#{klass.parent.name}::R::Dashboard".safe_constantize
      end

      def search_url(klass, query, params = {})
        super(klass, query, params.merge(id: request.params[:id]))
      end

      def dashboard_url
        r = "#{dashboard_index_url(klass)}/last_search"
        return r
      end

      def query_record
        return unless record&.loaded?
        super
      end

      def dashboard_index_url(klass)
        index_url(klass)
      end

    end
  end
end
