module Dynamic
  class Dashboard < Dynamic::Base
    define_api_path # /api/d/uneek/r__dashboards

    translates :human_name
    globalize_accessors

    class << self

      def includes_for_load
        {
          translations: 1,
          charts: {
            include: {
              translations: 1,
              groups: {
                include: {
                  translations: 1,
                  ranges: 1,
                }
              },
              columns: 1,
            }
          }
        }
      end

      def with_includes_for_load
        includes(includes_for_load)
      end

    end

    module Feature; extend ActiveSupport::Concern

      def self.load_constants(schema)
        dashboard_klass = schema.const_reserved_klass("Dashboard", ::Dynamic::Dashboard)
        chart_klass = schema.const_reserved_klass("Chart::Base", ::Dynamic::Chart::Base)
        chart_group_klass = schema.const_reserved_klass("Chart::Group", ::Dynamic::Chart::Group)
        chart_group_range_klass = schema.const_reserved_klass("Chart::Group::Range", ::Dynamic::Chart::Group::Range)

        chart_klass.belongs_to(:dashboard, class_name: dashboard_klass.name, inverse_of: :charts, load_from: :cache)
        dashboard_klass.has_many(:charts, class_name: chart_klass.name, inverse_of: :dashboard)

        chart_group_klass.belongs_to(:chart, class_name: chart_klass.name, inverse_of: :groups)
        chart_klass.has_many(:groups, class_name: chart_group_klass.name, inverse_of: :chart, foreign_key: :chart_id)

        chart_klass.has_many(:x_groups, class_name: chart_group_klass.name, foreign_key: :chart_id)
        chart_klass.has_many(:y_groups, class_name: chart_group_klass.name, foreign_key: :chart_id)
        chart_klass.has_many(:z_groups, class_name: chart_group_klass.name, foreign_key: :chart_id)

        chart_group_klass.has_many(:ranges, class_name: chart_group_range_klass.name, inverse_of: :group)
        chart_group_range_klass.belongs_to(:group, class_name: chart_group_klass.name, inverse_of: :ranges)
      end

    end

  end
end
