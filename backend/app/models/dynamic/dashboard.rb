module Dynamic
  class Dashboard < ActiveRecord::Base
    self.abstract_class = true

    include Dynamic::Mount

    define_table do |t|
      t.string :name
      t.string :human_name, translate: true
      t.belongs_to :user, type: :uuid
      t.belongs_to :item, type: :uuid
    end

    after_mount do |schema|
      has_many :charts, class_name: 'Chart::Base', inverse_of: :dashboard, dependent: :destroy
      accepts_nested_attributes_for :charts, allow_destroy: true
      belongs_to :user, optional: true
      menu_item_class = self.module_parent::Menu::Item
      belongs_to :item, class_name: menu_item_class.name, dependent: :destroy, optional: true

      Dynamic::Chart::Base.mount(schema)
      Dynamic::Chart::Group.mount(schema)
      Dynamic::Chart::Group::Range.mount(schema)
    end

    def attributes_for_duplicate
      exceptions = ['created_at', 'updated_at', 'deleted_at', 'id', 'user_id']

      dashboard_exceptions =
        exceptions +
        ['item_id'] +
        self.class.translated_attribute_names +
        self.class.translated_attribute_names.map{|e| I18n.available_locales.map{|a| "#{e}_#{a}"}}.flatten

      chart_exceptions =
        exceptions +
        ['dashboard_id'] +
        self.class.module_parent::Chart::Base.translated_attribute_names +
        self.class.module_parent::Chart::Base.translated_attribute_names.map{|e| I18n.available_locales.map{|a| "#{e}_#{a}"}}.flatten
      group_exceptions =
        exceptions +
        ['chart_id'] +
        self.class.module_parent::Chart::Group.translated_attribute_names +
        self.class.module_parent::Chart::Group.translated_attribute_names.map{|e| I18n.available_locales.map{|a| "#{e}_#{a}"}}.flatten

      range_exceptions =
        exceptions +
        ['group_id', 'chart_id']

      return self.as_deep_json(secure: false,
        except: dashboard_exceptions,
        include: {
          translations: {
            except: exceptions + ['owner_id'],
            as: :translations_attributes,
          },
          charts: {
            except: chart_exceptions,
            include: {
              translations: {
                except: exceptions + ['owner_id'],
                as: :translations_attributes,
              },
              groups: {
                except: group_exceptions,
                include: {
                  translations: {
                    except: exceptions + ['owner_id'],
                    as: :translations_attributes,
                  },
                  ranges: {
                    except: range_exceptions,
                  },
                  as: :ranges_attributes
                },
                as: :groups_attributes
              }
            },
            as: :charts_attributes
          }
        }
      )
    end

    module Feature; extend Dynamic::Feature

      def self.feature_attributes
        {
          human_name_fr: 'Tableau de bord',
          human_name_en: 'Dashboard',
          mandatory: true, # TODO make it not mandatory
        }
      end

      def self.load(schema)
        Dynamic::Dashboard.mount(schema)
      end

      def self.drop_tables(do_it = false) #for maintenance
        unless do_it
          puts "pass true as parameter if you really want to drop tables"
          return do_it
        end

        c = ActiveRecord::Base.connection
        Dynamic::Schema.all.each do |schema|
          c.drop_table("d_#{schema.name.underscore}_r_dashboards") if c.table_exists?("d_#{schema.name.underscore}_r_dashboards")
          c.drop_table("d_#{schema.name.underscore}_r_dashboard_translations") if c.table_exists?("d_#{schema.name.underscore}_r_dashboard_translations")
          c.drop_table("d_#{schema.name.underscore}_r_charts") if c.table_exists?("d_#{schema.name.underscore}_r_charts")
          c.drop_table("d_#{schema.name.underscore}_r_chart_translations") if c.table_exists?("d_#{schema.name.underscore}_r_chart_translations")

          c.drop_table("d_#{schema.name.underscore}_r_chart_bases") if c.table_exists?("d_#{schema.name.underscore}_r_chart_bases")
          c.drop_table("d_#{schema.name.underscore}_r_chart_basis_translations") if c.table_exists?("d_#{schema.name.underscore}_r_chart_basis_translations")

          c.drop_table("d_#{schema.name.underscore}_r_chart_groups") if c.table_exists?("d_#{schema.name.underscore}_r_chart_groups")
          c.drop_table("d_#{schema.name.underscore}_r_chart_group_translations") if c.table_exists?("d_#{schema.name.underscore}_r_chart_group_translations")

          c.drop_table("d_#{schema.name.underscore}_r_chart_group_ranges") if c.table_exists?("d_#{schema.name.underscore}_r_chart_group_ranges")

        end
        return true
      end

    end

    class Adapter

      attr_accessor :params
      attr_accessor :klass
      attr_accessor :time_zone

      TIME_ZONE_DEFAULT = 'Europe/Paris'
      MIN_DOC_COUNT_DEFAULT = 1
      SIZE_DEFAULT = 10
      CALENDAR_INTERVAL_DEFAULT = '1d'
      INTERVAL_DEFAULT = 1
      MISSING_VALUES = {
        'string'  => '_missing_',
        'date'    => Date.new(1987, 1, 1),
        'boolean' => false,
        'number'  => -1
      }.freeze

      def initialize(klass, params)
        @klass = klass
        @params = params
        @group = {}
        @y_groups = {}
        @z_groups = {}
        @time_zone = params[:time_zone] || TIME_ZONE_DEFAULT
      end

      def dashboard
        return unless params[:dashboard_id] && klass
        klass.module_parent::R::Dashboard.includes(
          charts: {
            groups: {
              ranges: {},
            }
          }
        ).find(params[:dashboard_id])
      end

      def self.charts_from_query(klass, query, dashboard_id = nil)
        if dashboard_id
          dashboard_klass = "#{klass.module_parent.name}::R::Dashboard".safe_constantize
          return [] unless dashboard_klass
          dashboard = dashboard_klass.includes(
            charts: {
              groups: {
                ranges: {},
              }
            }
          ).find(dashboard_id)
          return dashboard.charts
        else
          return unless query
          chart_short_ids = query.keys.select{|k| k.start_with?('chart-')}.map{|c| c.split('-').last}
          return [] unless chart_short_ids.any?

          chart_klass = "#{klass.module_parent.name}::R::Chart::Base".safe_constantize
          return [] unless chart_klass

          wheres = [chart_short_ids.map{|i| 'id::text LIKE ?'}.join(' OR ')] + chart_short_ids.map{|i| "%#{i}"}
          return chart_klass.where(*wheres).includes(groups: {}).all
        end
      end

      def charts
        @charts ||= self.class.charts_from_query(klass, search_query, params[:dashboard_id])
      end

      def as_json(*args)
        {
          charts: aggs(charts || []),
        }
      end

      def aggs(charts, treat_missing: true)
        searches = []
        charts.each_with_index do |c|
          group = group(c.id)
          next unless group
          show_missing = group[:show_missing] || false
          treat_missing_ = treat_missing && show_missing

          search = {
            aggs: {
              c.id => {
                (group[:agg] || 'terms') => field_or_script(group).merge(agg_params(group, chart: c))
              }
            }
          }

          if treat_missing_
            search[:aggs]["#{c.id}_missing"] = {
              filter: {
                bool: {
                  must_not: {
                    exists: field_or_script(group)
                  }
                }
              },
              aggs: {
              "#{c.id}_missing_agg" => {
                  (group[:agg] || 'terms') => field_or_script(group, for_missing: true).merge(agg_params(group))
                }

              }
            }
          end

          if z_groups(c.id).any?
            z_g = z_groups(c.id).first
            z_agg = { 'terms' => field_or_script(z_g).merge(agg_params(z_g)) }
            z_agg[:aggs] = y_aggs(c.id) if y_groups(c.id).any?
            search[:aggs][c.id][:aggs] = { z_g.id.to_s => z_agg }
          elsif y_groups(c.id).any?
            search[:aggs][c.id][:aggs] = y_aggs(c.id)
            if treat_missing_
              search[:aggs]["#{c.id}_missing"][:aggs]["#{c.id}_missing_agg"][:aggs] = y_aggs(c.id)
            end
          end

          filters = filters_from_other_charts(c)

          if q = q_filter
            filters = filters ? [q].concat(filters) : [q]
          end

          if sf = chart_search_filter(c, group)
            filters = filters ? [sf].concat(filters) : [sf]
          end

          not_deleted_filter = { bool: { must_not: { exists: { field: 'deleted_at' } } } }

          filters = [not_deleted_filter].concat(Array(filters))

          if filters
            search['query'] = {bool: {filter: filters}}
          end
          sort_state = sort_from_chart(c)
          apply_sort_to_agg(search, c, group, sort_state) if sort_state

          if search_query&.dig(c.url_id, 'drill')
            search[:aggs][c.id][:aggs] ||= {}
            search[:aggs][c.id][:aggs]["drill"] = {
              bucket_sort: {
                from: search_query[c.url_id]['drill'],
              }
            }
          end
          searches << {search: search}
        end
        return [] unless searches.any?

        s = msearch(searches)
        result = []

        s['responses'].each do |response|
          next unless response['aggregations']
          c_id = response['aggregations'].keys.first
          c_id = c_id.sub("_missing", "")
          missing_id_key = "#{c_id}_missing"

          agg = response['aggregations'][c_id]
          if agg.key?('value')
            result << {
              uuid: c_id,
              data: [
                {
                  key: 'value',
                  group(c_id)[:id] => agg['value']
                }
              ]
            }
            next
          end

          buckets = response.dig('aggregations', c_id, 'buckets')
          sum_other_doc_count = response.dig('aggregations', c_id, 'sum_other_doc_count')

          missing_values_count = response.dig('aggregations', missing_id_key, 'doc_count') || 0
          next unless buckets || missing_values_count != 0

          buckets << {'key' => '_others_', 'doc_count' => sum_other_doc_count} if sum_other_doc_count && group(c_id)[:show_others]
          data = []
          if missing_values_count > 0
            missing_buckets = response.dig('aggregations', missing_id_key, "#{missing_id_key}_agg", 'buckets')

            unless missing_buckets.nil? || missing_buckets.empty?
              missing_buckets.map do |h|
                r = {
                  key: '_missing_',
                  group(c_id)[:id] => h['doc_count'],
                }
                y_groups(c_id).each do |g|
                  r[g.id.to_s] = h[g.id.to_s]['value']
                end
                data << r
              end

            else
              data << [{ key: '_missing_', group(c_id)[:id] => missing_values_count}]
            end
          end

          if z_groups(c_id).any?
            result << build_chart_with_z_result(c_id, buckets, data, charts)
          else
            result << build_chart_result(c_id, buckets, data, charts)
          end
        end
        return result
      end

      def build_chart_with_z_result(c_id, buckets, data, charts)
        z_g = z_groups(c_id).first
        ygs = y_groups(c_id)
        all_z_keys = []

        if group(c_id).size.nil? || group(c_id).size > 0
          buckets.each do |h|
            r = { key: h['key'], group(c_id)[:id] => h['doc_count'] }
            (h.dig(z_g.id.to_s, 'buckets') || []).each do |zb|
              zk = zb['key'].to_s
              all_z_keys << zk unless all_z_keys.include?(zk)
              if ygs.any?
                ygs.each { |yg| r["#{zk}__#{yg.id}"] = zb.dig(yg.id.to_s, 'value') }
              else
                r[zk] = zb['doc_count']
              end
            end
            data << r
          end
        end
        sort_range_agg_data(data, charts, c_id) if group(c_id).agg == "range"
        { uuid: c_id, data: data, z_group_id: z_g.id.to_s, z_keys: all_z_keys, y_group_ids: ygs.map { |yg| yg.id.to_s } }
      end

      def build_chart_result(c_id, buckets, data, charts)
        if group(c_id).size.nil? || group(c_id).size > 0
          buckets.each do |h|
            r = { key: h['key'], group(c_id)[:id] => h['doc_count'] }
            y_groups(c_id).each { |g| r[g.id.to_s] = h[g.id.to_s]['value'] }
            data << r
          end
        elsif group(c_id)[:show_others]
          data << { key: '_others_', group(c_id)[:id] => buckets.sum { |h| h['doc_count'] } }
        end
        sort_range_agg_data(data, charts, c_id) if group(c_id).agg == "range"
        { uuid: c_id, data: data }
      end

      def sort_range_agg_data(data, charts, c_id)
        g = group(c_id)
        sort_state = sort_from_chart(charts.find{ |c| c.id == c_id})

        if sort_state
          dir_y = sort_state["y"]
          dir_x = sort_state["x"]

          ygs = ygs = y_groups(c_id)

          if dir_x
            data.sort_by! { |row| row[:key].to_s}
            data.reverse! if dir_x == "desc"
          end

          if dir_y
            if z_groups(c_id).any? && ygs.any?
              y_id = ygs.first.id.to_s
              data.sort_by! { |row| row.sum { |k, v| k.to_s.end_with?("__#{y_id}") ? v.to_f : 0 } }
            else
              sort_key = ygs.any? ? ygs.first.id.to_s : g.id.to_s
              data.sort_by! { |row| row[sort_key] }
            end
            data.reverse! if dir_y == 'desc'
          end
        end
      end

      def group(c_id)
        return @group[c_id] if @group[c_id]
        split_groups
        return @group[c_id]
      end

      def y_groups(c_id)
        return @y_groups[c_id] if @y_groups[c_id]
        split_groups
        return @y_groups[c_id]
      end

      def z_groups(c_id)
        return @z_groups[c_id] if @z_groups[c_id]
        split_groups
        return @z_groups[c_id]
      end

      def split_groups
        charts.each do |c|
          group = nil
          y_groups = []
          z_groups = []
          c.groups.each do |g|
            next if g.deleted_at
            if [nil, 'x'].include?(g.axis)
              group = g
            elsif g.axis == 'z'
              z_groups << g
            else
              y_groups << g
            end
          end
          @group[c.id] = group
          @y_groups[c.id] = y_groups
          @z_groups[c.id] = z_groups
        end
      end

      def y_aggs(c_id)
        y_groups(c_id).each_with_object({}) do |g, h|
          h[g.id.to_s] = { g.agg => field_or_script(g).merge(agg_params(g)) }
        end
      end

      def field_or_script(group, for_missing: false)
        r = {}
        value_type = group.value_type
        case group.source
        when 'script'
          r = {
            script: {
              source: group.script,
              lang: 'painless',
            },
            value_type: value_type,
          }
        when 'attr'
          field_name = group.value_type == "string" ? "#{group.attr}.keyword" : group.attr
          r = { field: field_name}
          if for_missing && MISSING_VALUES.key?(value_type)
            r[:missing] = MISSING_VALUES[value_type]
          end
        end
        r
      end

      def agg_params(group, chart: nil)
        params = AGG_PARAMS[group.agg]&.call(group, time_zone) || {}
        if chart && group.agg == 'terms'
          drill_value = search_query&.dig(chart.url_id, 'drill')
          if drill_value && drill_value != 0
            params[:size] += drill_value
          end
        end
        params
      end

      def filters_from_other_charts(chart)
        result = []
        charts.each do |c|
          exclusion_filters = exclusion_filters_from_chart(c)
          result << exclusion_filters if exclusion_filters
          next if c.id == chart.id
          f = filters_from_chart(c)
          result << f if f
        end
        return result.any? ? result : nil
      end

      def chart_keys_for_group(chart)
        g = group(chart.id)
        return [] unless g
        keys = []

        chart_data = aggs([chart], treat_missing: false).find { |c| c[:uuid] == chart.id.to_s }
        return [] unless chart_data && chart_data[:data]
        chart_data[:data].each do |entry|
          keys << entry[:key] if entry[:key] != '_others_'
        end
        keys
      end

      def exclusion_filters_from_chart(c)
        return unless c
        return if c.type == 'Table'
        return unless search_query
        return unless search_query[c.url_id]

        exclusion_filters = search_query[c.url_id]['exclusion_filters']
        return if exclusion_filters.nil?
        exclusion_filters = Array(exclusion_filters) unless exclusion_filters.is_a?(Array)

        g = group(c.id)
        return unless g.source == 'attr'
        if g.value_type == "boolean"
          exclusion_filters = normalize_boolean_filter(exclusion_filters)
        end
        g_attr = g.value_type == "string" ? "#{g.attr}.keyword" : g.attr

        if g.agg == "range"
          range_must_nots = build_range_query(exclusion_filters, g_attr)
          return if range_must_nots.empty?
          return { bool: { must_not: range_must_nots } }
        else
          return { bool: { must_not: { terms: { g_attr => exclusion_filters } } } }
        end
      end

      def filters_from_chart(c)
        return unless c

        if c.type == 'Table'
          filters = ::Dynamic::Filters::Converter.new(search_query&.dig(:filters) || {}, {}, time_zone).to_es_query
          return filters&.any? ? filters : nil
        else
          return unless search_query
          return unless search_query[c.url_id]
          filters = search_query[c.url_id]['filters']
          return if filters.nil?

          filters = Array(filters) unless filters.is_a?(Array)

          g = group(c.id)
          return unless g.source == 'attr' # how scripted group can be filtered ?

          if g.value_type == "boolean"
            filters = normalize_boolean_filter(filters)
          end

          g_attr = g.value_type == "string" ? "#{g.attr}.keyword" : g.attr

          if c.type == "Line" || g.agg == 'date_histogram' || g.agg == 'auto_date_histogram' || g.agg == 'histogram'
            if filters&.any?
              filters = filters.map do |d|
                if d.to_s =~ /\d{4}\-\d{2}\-\d{2}/
                  DateTime.parse(d.gsub('%2B', '+')).iso8601
                else
                  d
                end
              end
              return { range: { g_attr => {from: filters[0], to: filters[1]} } }
            end
          else
            combined_filters = []
            if filters.include?('_others_')
              chart_keys = chart_keys_for_group(c)
              others_filter = { must: { exists: { field: g_attr } } }
              others_filter[:must_not] = { terms: { g_attr => chart_keys } } if chart_keys.any?
              combined_filters << { bool: others_filter }
            end

            if filters.include?('_missing_')
              combined_filters << { bool: { must_not: { exists: { field: g_attr } } } }
            end

            rest_of_filters = filters.reject { |f| ['_missing_', '_others_'].include?(f) }
            unless rest_of_filters.empty?
              if g.agg == "range"
                range_filters = build_range_query(rest_of_filters, g_attr)
                combined_filters.concat(range_filters) if range_filters.any?
              else
                combined_filters << { terms: { g_attr => rest_of_filters } }
              end
            end
            return if combined_filters.empty?
            if combined_filters.length == 1
              return combined_filters.first
            else
              return { bool: { should: combined_filters,  minimum_should_match: 1 } }
            end
          end
        end
      end

      def build_range_query(filters, g_attr)
        filters.map do |f|
          r1, r2 = f.to_s.split("-", 2)
          next if r1.blank? || r2.blank?
          { range: { g_attr => { from: r1, to: r2} } }
        end.compact
      end

      def normalize_boolean_filter(filters)
        filters = filters.map do |f|
          if f.to_s == "0" then false
          elsif f.to_s == "1" then true
          else f
          end
        end
        return filters
      end

      def sort_from_chart(c)
        return unless c
        return unless search_query
        return unless search_query[c.url_id]
        if c.type == 'Table'
          return nil
        end
        sort_state = search_query[c.url_id]['order']
        return nil unless sort_state
        return nil unless sort_state.is_a?(Hash)
        valid = %w[asc desc]
        x = sort_state['x']
        y = sort_state['y']

        sort_state['x'] = valid.include?(x) ? x : nil
        sort_state['y'] = valid.include?(y) ? y : nil
        return nil if sort_state['x'].nil? && sort_state['y'].nil?
        return sort_state
      end

      def apply_sort_to_agg(search, chart, group, sort_state)
        return unless sort_state && group
        agg_name = (group[:agg] || 'terms')
        return if agg_name == "range" || agg_name == "auto_date_histogram"
        dir_x = sort_state[:x]
        dir_y = sort_state[:y]
        if dir_y
          if z_groups(chart.id).any?
            search[:aggs][chart.id][agg_name][:order] = [{ "_count" => dir_y }]
          else
            ygs = y_groups(chart.id)
            if ygs.any?
              search[:aggs][chart.id][agg_name][:order] = ygs.map { |yg| { yg.id.to_s => dir_y } }
            else
              search[:aggs][chart.id][agg_name][:order] = [{ "_count" => dir_y }]
            end
          end
        end

        if dir_x
          current_order = search[:aggs][chart.id][agg_name][:order]
          if current_order.nil?
            search[:aggs][chart.id][agg_name][:order] = { "_key" => dir_x }
          else
            search[:aggs][chart.id][agg_name][:order] << { "_key" => dir_x }
          end
        end
      end
      AGG_PARAMS = {
        'date_histogram' => lambda do |group, time_zone|
          {
            calendar_interval: group.calendar_interval || CALENDAR_INTERVAL_DEFAULT,
            time_zone: time_zone,
            min_doc_count: group.min_doc_count || MIN_DOC_COUNT_DEFAULT,
          }
        end,

        'auto_date_histogram' => lambda do |group, time_zone|
          {
            buckets: (group.size && group.size > 0) ? group.size : SIZE_DEFAULT,
            time_zone: time_zone,
          }
        end,

        'date_range' => lambda do |group, time_zone|
          {
            ranges: group.ranges.map{|i| {from: i.from, to: i.to}}, #[{"from": "now-1w/w", "to": "now"}]
            time_zone: time_zone,
          }
        end,

        'histogram' => lambda do |group, time_zone|
          {
            "interval": group.interval || INTERVAL_DEFAULT,
            "min_doc_count": group.min_doc_count || MIN_DOC_COUNT_DEFAULT
          }
        end,

        'range' => lambda do |group, time_zone|
          {
            ranges: group.ranges.map{|i| {from: i.from, to: i.to}},
          }
        end,

        'terms' => lambda do |group, time_zone|
          {
            size: (group.size && group.size > 0) ? group.size : SIZE_DEFAULT
          }
        end,
      }

      def q_filter
        return unless search_query && search_query[:q].present?
        return {
          query_string: {
            query: "*#{self.class.sanitize_string_for_elasticsearch_string_query(search_query[:q])}*"
          }
        }
      end

      def chart_search_filter(chart, group)
        term = search_query&.dig(chart.url_id, 'contains')
        return unless term.present?

        if group.value_type == 'number' || group.value_type == 'date'
          query = "\"#{term.to_s.gsub(' ', '\ ')}\""
        else
          query = "*#{term.downcase.gsub(' ', '\ ')}*"
        end

        { query_string: { query: query, fields: [group.attr] } }
      end

      def self.sanitize_string_for_elasticsearch_string_query(str)
        Dynamic::Datatable::Elasticsearch.sanitize_string_for_elasticsearch_string_query(str)
      end

      def search_query
        @search_query ||= case params[:search_query]
        when String
          (Rison.parse(params[:search_query]) rescue {}).with_indifferent_access
        when ActionController::Parameters
          params[:search_query].permit!
        when Hash
          params[:search_query].with_indifferent_access
        end
      end

      def msearch(searches)
        if @klass.include?(Dynamic::Permission::OpenSearch::ControlledKlass)
          return @klass.msearch_as(User.current, searches)
        else
          s = {index: @klass.__opensearch__.index_name, body: searches}
          return @klass.__opensearch__.client.msearch(s)
        end
      end
    end

  end
end
