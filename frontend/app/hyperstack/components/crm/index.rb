# backtick_javascript: true
require 'components/wait_for_completed_jobs'

class Crm
  class Index < Base
    include OutsideOfRendering

    param :klass

    render do
      Crm::GlobalToolbarAndPanels(klass: klass) do
        if layout_id
          if dynamic_layout.not_found?
            Layout::Manager(klass: klass, layout_id: layout_id, menu_item_id: request.params[:mi], rerender_after_create: false)
            .on(:created) do |layout|
              change_layout(layout.id)
            end.on(:layout_changed) do
              dynamic_layout.reload
            end.on(:select_layout) do |layout_id|
              change_layout(layout_id)
            end
          elsif dynamic_layout.deleted?
            redirect_to_first_layout
          else
            Layout(key: layout_key, dynamic_layout: dynamic_layout, klass: klass, match: match)
          end
        else
          redirect_to_first_layout
        end
      end
    end

    def layout_id
      if request.params[:_] && request.params[:_] =~ /[\(,]l\:'([^']+)'/
        return $1
      end
      request.params[:l]
    end

    def dynamic_layout
      observe Dynamic::Layout
        .with_action('index')
        .with_deleted
        .where(schema_id: schema.name, klass_name: klass.name)
        .includes(Dynamic::Layout.includes_for_load).find(layout_id)
    end

    after_mount do
      App.change_theme_if_missing
    end

    module ChangeLayout; extend ActiveSupport::Concern

      def change_layout(layout_id)

        if request.params[:_]
          s = request.location.search
          if s.blank? && request.location.pathname.include?('?')
            # workaround a bug. probably in https://github.com/remix-run/history/tree/v4
            # TODO upgrade to react > 17
            s = request.location.pathname.split('?', 2).last.to_s
          end

          if has_l_in_rison?(s)
            url = replace_l_in_rison(s, layout_id)
          else
            url = append_l_to_rison(request.params, layout_id)
          end
        else
          url = s.to_s
          _param = "_=(l:'#{layout_id}')"
          sep = url.include?('?') ? '&' : '?'
          url = "#{url}#{sep}#{_param}"
        end

        App.history.replace(url)
        mutate
      end

      def has_l_in_rison?(url)
        !!(url =~ /[\(,]l:('|%)/)
      end

      def replace_l_in_rison(rison, l)
        return rison.gsub(/([\(,])l\:('|%27)[^'%]+('|%27)/, "\\1l\:\\2#{l}\\3")
      end

      def append_l_to_rison(params, l)
        params[:_] = params[:_][0..-2] + ",l\:'#{l}')"
        return "?" + params.map{|p| "#{p[0]}=#{p[1]}"}.join('&')
      end

    end; include ChangeLayout

    def redirect_to_first_layout
      observe first_layout = Dynamic::Layout
        .with_action('index')
        .where(schema_id: schema.name, klass_name: klass.name)
        .first

      if first_layout.nil? || first_layout.not_found?
        redirect_to_new_layout
      elsif first_layout.loaded?
        outside_of_rendering do
          u = App.location.add_params(l: first_layout.id)
          u['search'] = u['search'].gsub(/,l\:'[^']+'/, '') if u['search']
          App.history.replace(u)
        end
      end
    end

    def redirect_to_new_layout
      # TODO
    end

    def layout_key
      "layout-#{dynamic_layout.id}-#{request.params[:action]}"
    end

    class Base < ::Crm::Base
      include OutsideOfRendering
      include CrmLayout
      include UrlHelper
      include WaitForCompletedJobs
      include WindowTitle
      include Crm::WithPageTitleAndLayoutSelector
      include Crm::Index::ChangeLayout

      param :klass, default: nil
      param :timestamp, default: nil

      after_update do
        show_or_hide_panels
      end

      after_mount do
        ::HyperResource::Base.subscribe_to_after_completed_jobs
        show_or_hide_panels
        self.jq_node.on('reload.crm.index') do
          reload
        end
      end

      before_unmount do
        ::HyperResource::Base.unsubscribe_to_after_completed_jobs
      end

      # Routes -------------------------------------------------

      def index_url(klass)
        return interpolate_path("/crm/:schema/table/:klass", {
          schema: klass.parent.name.demodulize.underscore,
          klass: klass.model_name.route_key,
        })
      end

      def import_url
        return interpolate_path("/crm/:schema/import_settings", {
          schema: klass.parent.name.demodulize.underscore
        })
      end

      def search_url(klass, query, params = {})
        params = params.merge(additional_params_for_search)

        r = index_url(klass)

        query = SearchQuery.new(query) unless query.is_a?(SearchQuery)

        if query.params.any?
          return "#{r}/search?#{encode_url_params({_: query.dump}.merge!(params))}"
        else
          if params.any?
            return "#{r}?#{encode_url_params(params)}"
          end
        end
        return r
      end

      def additional_params_for_search
        result = {}
        result[:rp] = request.params[:rp] if request.params[:rp]
        result[:lp] = request.params[:lp] if request.params[:lp]
        result[:l] = request.params[:l] if request.params[:l]
        result[:mi] = request.params[:mi] if request.params[:mi]
        return result
      end

      def setting_merge_url(record_param_ids)
        schema = request.params[:schema]
        record_to_merge_ids = record_param_ids.join('&record_to_merge_ids[]=')
        url = "/crm/#{schema}/merge_settings/new?result_record_type=#{klass}&record_to_merge_ids[]=#{record_to_merge_ids}"
        url = add_param_to_url(url, :mi, request.params[:mi]) if request.params[:mi].present?
        return url
      end

      def last_search_url
        r = "#{index_url(klass)}/last_search"
        r = add_param_to_url(r, :l, request.params[:l]) if request.params[:l].present?
        r = add_param_to_url(r, :mi, request.params[:mi]) if request.params[:mi].present?
        return r
      end

      def history
        App.history
      end

      # Search ------------------------------------------------

      after_new_params do
        init
      end

      before_new_params do |next_props|
        @next_klass = next_props[:klass]
      end

      def init
        update_page_title
        return unless ready_for_init_search_query?

        if reset_search_query?
          search_query.reset(request.params[:_], search_query_defaults)
        end
        search_query

        if reset_query_record?
          @query_record = nil
        end

        query_record
      end

      def update_page_title
        return unless @previous_page_title != page_title
        @previous_query_name = request.params[:query_name] if @previous_query_name != request.params[:query_name]
        @previous_klass = request.params[:klass] if @previous_klass != request.params[:klass]
        @previous_menu_item_id = request.params[:mi] if @previous_menu_item_id != request.params[:mi]
        @previous_page_title = page_title
      end

      def ready_for_init_search_query?
        true
      end

      def search_query
        return unless ready_for_init_search_query?
        @search_query ||= SearchQuery.new(request.params[:_], search_query_defaults)
      end

      def search_query_defaults
      end

      def search_query_params
        search_query&.params
      end

      track_changes :search_query_params

      def query_record
        @query_record ||= ::User.current.queries
          .merge_where(schema_name: schema_name, type: 'Current')
          .create_with(params: search_query&.params || {})
          .find_or_create_by(path: query_path) do |r|
          if r.persisted?
            if request.params[:action] == 'last_search'
              @prevent_reset_query_record = true
              outside_of_rendering do
                if request.params[:action] == 'last_search'
                  @search_query = nil
                  @prevent_reset_query_record = false
                  search_params = r.params[:mi] ? {} : {mi: first_menu_item_id_of_klass}
                  App.history.replace(search_url(@next_klass || klass, r.params, search_params))
                end
              end
            end
          end
        end
      end

      def query_path
        return "#{menu_item_id_with_fallback}:#{base_query_path}"
      end

      def menu_item_id_with_fallback
        request.params[:mi] || first_menu_item_id_of_klass
      end

      def first_menu_item_id_of_klass
        menu = User.current.menus.merge_where(schema_name: schema_name, name: 'crm').first
        return unless menu&.loaded? # should not happen
        menu.items.detect{|i| i.link =~ /crm\/[^\/]*\/table\/#{request.params[:klass]}(\/|$|\?|&)/}&.id
      end

      def base_query_path
        # index_url(klass)
        request.location.pathname.gsub(/\/search.*$|\/last_search.*$/, '')
      end

      def search
        update_query_record
        App.history.push(search_url(klass, search_query))
      end

      def update_query_record
        query_record.update(params: search_query&.params || {}) if query_record.loaded?
      end

      def reset_search_query?
        query_path_changed? || location_query_changed?
      end

      def reset_query_record?
        query_path_changed? || (request.params[:action] == 'last_search' && !@prevent_reset_query_record)
      end

      def query_path_changed?
        @previous_query_path != query_path
      end

      def action_changed?
        return false if @previous_action == 'index' && request.params[:action] == 'search'
        return false if @previous_action == 'search' && request.params[:action] == 'index'
        !@previous_action.nil? && request.params[:action] != @previous_action
      end

      def location_query_changed?
        @previous_location_query != request.params[:_]
      end

      def reload
        @reload = Time.now.to_f # TODO replace by an incremented integer
        mutate
      end

      def reload?
        @reload
      end

      def reset_filters
        @search_query&.reset_filters
        @search_input_draw = (@search_input_draw || 0) + 1
        search
      end

      def reset_order
        @search_query&.reset_order
        search
      end

      after_render do
        after_render_search
      end

      def after_render_search
        store_previous_states
      end

      def store_previous_states
        @previous_pathname = request.location.pathname
        @previous_query_path = query_path
        @previous_action = request.params[:action]
        @previous_location_query = request.params[:_]
      end

      def ask_for_delete_selected_records
        relation = selected_records_relation
        if relation
          relation.count do |count|
            Modal.confirm(title: I18n.t('crm.delete_records', count: count, klass_name: klass.model_name.human(count: count).downcase)) do
              async = count > async_threshold
              relation.destroy_all(wait_for_completed_jobs_options.merge(async: async)).then do |response|
                if response[:success]
                  next if async
                  reload
                else
                  # TODO improve long tasks and error handling
                  notification_klass = "#{klass.parent.name}::R::Notification".safe_constantize
                  notification_klass&.create(
                    icon: 'bug',
                    title: I18n.t('shared.delete'),
                    body: I18n.t('shared.error'),
                    user_id: User.current.id,
                  )
                end
              end
            end
          end
        end
      end

      def merge_all_selected_records
        all_selected_ids do |ids|
          App.history.push(setting_merge_url(ids))
        end
      end

      def copy_all_selected_records
        all_selected_ids do |ids|
          records = (ids || []).map { |id| klass.new(id: id) }
          ::Element.find('#copy-run-modal').trigger('show.dynamo.modal', [{ records: records }])
        end
      end

      def all_selected_ids
        if all_selected?
          r = selected_records_relation
          if r
            r.stale!
            r.all do |r|
              yield(r.map(&:id)) # limited by server
            end
          else
            yield([])
          end
        else
          yield(selected_record_ids || [])
        end
      end

      def selected_records_relation
        if all_selected?
          return all_selected_records_relation
        else
          if selected_record_ids&.any?
            return klass.where(id: selected_record_ids)
          else
            return nil
          end
        end
      end

      def all_selected_records_relation
        result = relation
        if selected_record_ids&.any?
          result = result.where.not(id: selected_record_ids)
        end
        return result
      end

      def relation
        result = klass
        result = result.where_query(search_query.params) if apply_where_query_scope?(search_query)
        return result
      end

      def apply_where_query_scope?(search_query)
        search_query && (search_query.dig(:filters).try(:any?) || search_query[:q].present? || search_query.params.keys.detect{|k| k.start_with?('chart-')})
      end

      def export_records_relation
        selected_records_relation || all_selected_records_relation
      end

      def all_selected?
      end

      def toolbar_import_button
        return unless User.current.can_read?('Dynamic::Import::Setting', schema: schema)
        Toolbar::Button(target: import_url, text: Dynamic::Import::Setting.model_name.human, icon: Dynamic::Import::Setting.icon, is_flex: true, variant: 'primary')
      end

      def toolbar_delete_button(disabled: false)
        Toolbar::Button(text: I18n.t('shared.delete'), icon: 'trash', is_flex: true, variant: 'primary', disabled: disabled).on(:click) do |event|
          event.prevent_default
          ask_for_delete_selected_records
        end
      end

      def toolbar_export_button(disabled: false)
        return unless schema.has_feature_enabled?('Dynamic::Export::Feature') && User.current.can_read?(schema.absolute_reserved_klass_name('Export::Setting'), schema: schema)
        Toolbar::Button(text: Dynamic::Export::Setting.model_name.human, icon: Dynamic::Export::Setting.icon, is_flex: true, variant: 'primary', disabled: disabled).on(:click) do |event|
          event.prevent_default
          @export_all = true
          mutate
          after(0.1) do
            ::Element['#export-all-modal'].modal('show')
          end
        end
      end

      def toolbar_doc_gen_button(disabled: false)
        return unless schema.const.feature_enabled?('Dynamic::DocGen::Feature') && User.current.can_read?(schema.absolute_reserved_klass_name('DocGen::Template'), schema: schema)
        Toolbar::Button(text: I18n.t('doc_gen.generate'), icon: I18n.t('icons.models.dynamic/doc_gen/template'), is_flex: true, variant: 'primary', disabled: disabled).on(:click) do |event|
          yield(event) if block_given?
        end
      end

      def selected_record_ids
      end

      def async_threshold
        25
      end

      def redirect_to_index_with_a_right_panel_if_show_or_edit_record
        return unless request.params[:id]
        if request.params[:action] == :show
          Redirect(index_url(klass) + "?rp=#{request.location.pathname}/edit")
        elsif request.params[:action] == :edit
          Redirect(index_url(klass) + "?rp=#{request.location.pathname}")
        end
      end

      def global_toolbar
        global_toolbar_left
        global_toolbar_center
        global_toolbar_right
        global_toolbar_bottom
      end

      def change_layout(layout_id)
        if layout_id == 'new'
          super(HyperResource::Base.generate_uuid)
        else
          search_query[:l] = layout_id
          search
        end
      end

      def layout_id
        search_query.try(:[], :l) || request.params[:l]
      end

      def global_toolbar_center
        # can be redefined
      end

      def global_toolbar_right
        # can be redefined
      end

      def global_toolbar_bottom
      end

      def bottom_panel_delete_button
        BottomPanel::Button(text: I18n.t('shared.delete'), icon: 'trash').on(:click) do |event|
          event.prevent_default
          ask_for_delete_selected_records
        end
      end

      def bottom_panel_layout_selector_button
        BottomPanel::Button(target: "#display-mode-modal", text: I18n.t('crm.display_mode'), icon: 'window-restore', toggle: "modal").on(:click) do |event|
          ::Element['#bottom-panel'].modal('hide')
        end
      end

      def bottom_panel_layout_selector
        BottomPanel(id: "display-mode-modal", columns_render: 1) do
          Layout::Selector::BottomList(schema: schema, layout_id: layout_id, klass: klass, menu_item_id: request.params[:mi]).on(:change) do |l|
            ::Element['#display-mode-modal'].modal('hide')
            search_query[:l] = l
            search
          end
        end
      end

      def global_search_input
        DIV(class: 'p-2 flex-fill search-input-field d-none bg-light-yiq border-bottom') do
          SearchInput(search_query: search_query, draw: @search_input_draw).on(:launch_search) do
            search
          end
        end
      end

      def footer
        Footer(class: "d-md-none d-flex toolbar flex-row fixed-bottom bg-light") do
          DIV(class: "col align-self-center text-center") do
            Toolbar::Button(target: new_url(klass), text: I18n.t('shared.new'), text_break: '', icon: 'plus', is_flex: true, "data-open-panel": true)
            Toolbar::Button(text: I18n.t('shared.refresh'), icon: 'refresh', is_flex: true).on(:click) do |event|
              event.prevent_default
              reload
            end
            Toolbar::Button(text: '', text_break: '', icon: 'bars', is_flex: true, target: "#bottom-panel", toggle: "modal")
          end
        end
      end

      def edit_query_dialog
        Query::Dialog(id: 'edit_query_dialog', path: base_query_path, query: search_query, record: query_record, layout_id: layout_id, reload: reload?).on(:apply) do |query|
          next unless query
          App.history.push(search_url(klass, query.params, {query_name: query.human_name}))
        end
      end

      class ParamsConverter < ::Layout::ParamsConverter

        converter_for 'Crm::Table', 'Crm::List', 'Crm::Dashboard', 'Crm::Kanban', 'Crm::FileManager' # TODO compute atomatically

        def apply(params, options = {})
          return {klass: options.dig(:layout_params, :klass), timestamp: App.request.object_id}
        end

      end

    end

    module Exportable
      extend ActiveSupport::Concern
      included do
        def ordered_csv_headers
          result = {}
          I18n.with_locale(Form.current.submission.params.values.first[:locale]) do
            datatable_columns_to_export&.each do |co|
              result[co.name.gsub(/\]|\[/, '')] = co.human_path_without_cache.join(' > ')
            end
          end
          result
        end
      end

      def export_all_modal
        return unless @export_all
        Crm::ExportAllModal(id: 'export-all-modal', size: 'md', klass: klass).on(:confirm) do |export_options|
          setting_class = "D::#{schema.name}::R::Export::Setting".safe_constantize
          setting_class.create(
            klass_name_to_export: klass,
            status: 'to_do',
            scope_for_records_to_export: export_records_relation.is_a?(HyperResource::Relation) ? export_records_relation.scope : {},
            attrs_to_export: compute_columns_to_export,
            ordered_csv_headers: ordered_csv_headers,
            export_type: export_options[:export_type],
            encoding_type: export_options[:encoding_type],
            separator: export_options[:separator],
            decimal_separator: export_options[:decimal_separator],
            locale: export_options[:locale],
            date_format: export_options[:date_format],
            apply_attribute_format: export_options[:apply_attribute_format],
            user_id: User.current&.id,
          )
        end.on(:close) do
          @export_all = nil
        end
      end

      def compute_columns_to_export
        columns = datatable_columns_to_export
        result = {}
        columns&.each do |column|
          col = column.name.gsub('[]', '')
          path = col.split('.')
          prev = nil
          r = result
          current_klass = klass
          path_size = path.size
          path&.each_with_index do |attr, i|
            if current_klass.reflect_on_association(attr)
              current_klass = current_klass.reflect_on_association(attr).klass
              r[attr] ||= {}
              if i == path_size - 1
                r[attr][attr] = current_klass.name_attribute if current_klass
              end
            end

            if r[prev] == 1
              r[prev] = {}
              r[prev][attr] = 1
              r = r[prev]
            elsif r[prev]&.is_a?(Hash)
              r[prev][attr] = 1
            else
              if r[attr].nil?
                r[attr] = 1
              elsif r[attr].is_a?(Hash)
                r = r[attr]
              elsif r[attr] == 1
                r[attr] = {}
                r = r[attr]
              end
            end
            prev = attr
          end
        end
        return result
      end
    end
  end
end
