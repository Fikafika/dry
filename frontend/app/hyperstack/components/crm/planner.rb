class Crm
  class Planner < Crm::Index::Base
    include ::Crm::Routes::Helpers

    param :resources

    collect_other_params_as :other_params

    track_changes [:search_query, :params, :planner, :bucket_filter]

    DEFAULT_EVENT_NAME = "\u00A0".freeze

    BUCKET_DEFAULT_WIDTH = 16

    before_mount do
      @show_settings_dialog = false
      @bucket_list_width = search_query.dig('planner', 'bucket_width') || BUCKET_DEFAULT_WIDTH
    end

    after_mount do
      effective_resources
    end

    after_new_params do
      reload if search_query_params_planner_bucket_filter_changed?
    end

    before_render do
      @current_record_id = extract_current_record_id
    end

    render(DIV, class: 'crm-index') { content }

    def content
      global_toolbar

      if klass_is_configured?
        redirect_to_index_with_a_right_panel_if_show_or_edit_record

        DIV(class: 'container-fluid px-4 py-2') do
          DIV(class: 'd-flex m-0') do
            ResizablePanel(
              width: @bucket_list_width,
              min_width: 10,
              max_width: 50
            ) do
              bucket_list_content
            end.on(:width_changed) { |new_width| update_bucket_width(new_width) }
            DIV(class: 'pr-0', style: { flex: 1, minWidth: 0 }) do
              planner
            end
          end
        end

        edit_query_dialog
        settings_dialog
        planner_filters_dialog
        resource_filters_dialogs
        footer
      else
        DIV(class: 'p-2') do
          DIV(class: 'alert alert-warning') do
            ::I18n.t('crm.planner.module_missing_on_klass', klass: klass.model_name.human.capitalize)
          end
        end
      end
    end

    def extract_current_record_id
      rp_param = App.location.query['rp']
      if rp_param.present?
        id_match = rp_param.match(/\/([^\/]+)\/edit\z/)
        id_match ? id_match[1] : nil
      else
        nil
      end
    end

    def current_record_id
      @current_record_id
    end

    def bucket_list_content
      DIV(class: 'w-100 border-bottom p-2 bg-light') do
        DIV(class: 'd-flex justify-content-between align-items-center mb-2') do
          SPAN { I18n.t('crm.planner.bucket_list.title') }
          SPAN(class: 'badge badge-pill badge-secondary') { bucket_count }
        end
        Crm::Planner::SearchWithFilters(
          default_value: search_query.dig('planner', 'bucket_filter', klass.name_attribute, 'contains') || '',
          filter_present: bucket_filter_present?,
          modal_target: '#planner_filters_dialog',
        ).on(:search_changed) do |search_text|
          apply_bucket_search(search_text)
        end
      end
      DIV(id: 'external-events') do
        InfiniteScroll(DIV, class: 'container-fluid', items: list_filters.per(20), reload: @reload) do |record, i|
          event_data = {resourceIds: resource_ids_from_record(record)}
          is_selected = current_record_id == record.id
          css_classes = ['fc-event', 'mt-1', 'pl-2', 'text-white', 'border', 'cursor-grab']
          css_classes << (is_selected ? 'bg-secondary' : 'bg-primary')
          css_classes << 'shadow-lg' if is_selected
          DIV(class: css_classes.join(' '),
            id: record.id,
            draggable: true, 'data-event': event_data.to_json,
            'data-toggle': 'tooltip', 'title': record.try(klass.name_attribute), style: { userSelect: 'none' }
          ) do
            DIV(class: 'position-relative') do
              DIV(class: 'text-truncate') do
                record.try(klass.name_attribute) || DEFAULT_EVENT_NAME
              end
              DIV(
                class: 'position-absolute h-100 col-6', style: {top: 0, left: 0, zIndex: 1030},
                title: I18n.t('crm.planner.modal.replace_btn_text'), 'data-toggle': 'tooltip'
              ).on(:mouse_enter) do |evt|
                next unless ::Element.find('.fc-event-dragging').empty?
                elem = ::Element.find(evt.current_target.to_n).first.parents('.fc-event')
                elem.attr('data-event', event_data.merge({drag_type: 'replace'}).to_json)
              end
              DIV(id: 'middle-line', class: 'position-absolute d-none bg-light', style: {top: 0, bottom: 0, left: '50%', width: '2px', zIndex: 1030})
              DIV(
                class: 'position-absolute h-100 col-6', style: {top: 0, left: '50%', zIndex: 1030},
                title: I18n.t('crm.planner.modal.add_btn_text'), 'data-toggle': 'tooltip'
              ).on(:mouse_enter) do |evt|
                next unless ::Element.find('.fc-event-dragging').empty?
                elem = ::Element.find(evt.current_target.to_n).first.parents('.fc-event')
                elem.attr('data-event', event_data.merge({drag_type: 'add'}).to_json)
              end
            end
          end.on(:mouse_enter) do |evt|
            element = ::Element.find(evt.current_target.to_n).find('#middle-line').first
            element.remove_class('d-none') if element
          end.on(:mouse_leave) do |evt|
            element = ::Element.find(evt.current_target.to_n).find('#middle-line').first
            element.add_class('d-none') if element
          end.on(:click) do |evt|
            App.history.push(App.location.add_params(rp: edit_url(klass, record.id)))
          end
        end
      end
    end

    def settings_dialog
      SettingsDialog(
        id: 'planner_settings_dialog',
        query_record: query_record,
        search_query: search_query,
        size: 'lg',
        show: @show_settings_dialog,
      ).on(:apply) do |params|
        search_query['planner'] ||= {}
        search_query['planner'].merge!(params['planner']) if params['planner']
      end.on(:close) do
        @show_settings_dialog = false
        mutate
      end
    end

    def apply_bucket_search(search_text)
      search_query['planner'] ||= {}
      search_query['planner']['bucket_filter'] ||= {}
      bucket_filter = search_query['planner']['bucket_filter']
      if search_text.present?
        bucket_filter[klass.name_attribute] = { contains: search_text }
      else
        bucket_filter.delete(klass.name_attribute)
      end
      search
    end

    def resource_filters_dialogs
      (search_query.dig('planner', 'resources')&.keys || []).each do |resource_name|
        resource_klass = klass.reflect_on_association(resource_name.to_sym)&.klass
        next unless resource_klass
        render_filters_dialog(
          id: "resource_filters_dialog_#{resource_name}",
          klass: resource_klass,
          label: I18n.t('crm.query.params.planner.filters_for_resources'),
          filter_target: { name: 'filters', path: ['planner', 'resources', resource_name] },
          on_apply: -> { reload }
        )
      end
    end

    def planner_filters_dialog
      render_filters_dialog(
        id: 'planner_filters_dialog',
        klass: klass,
        label: I18n.t('crm.query.params.planner.filter_for_bucket'),
        filter_target: { name: 'bucket_filter', path: ['planner'] },
        on_apply: -> { search }
      )
    end

    def render_filters_dialog(id:, klass:, label:, filter_target:, on_apply:)
      FiltersDialog(
        id: id,
        search_query: search_query,
        query_record: query_record,
        klass: klass,
        size: 'lg',
        label: label,
        filter_name: filter_target[:name],
        filter_path: filter_target[:path]
      ).on(:apply, &on_apply)
    end

    def planner
      Crm::Planner::View(
        relation: klass,
        query: search_query,
        query_record: query_record,
        draggable_node_id: 'external-events',
        reload: @reload,
        interval: search_query['planner']['interval'],
        view_type: search_query['planner']['view_type'],
        event_duration: search_query['planner']['event_duration'],
        min_day_time: search_query['planner']['min_day_time'],
        max_day_time: search_query['planner']['max_day_time'],
        slot_duration: search_query['planner']['slot_duration'],
        last_date: search_query['planner']['last_date'],
        q: search_query['q'],
        resources: search_query['planner']['resources'],
        colors: other_params[:colors] || {},
        current_record_id: current_record_id,
      ).on(:resource_added) do |name|
        search_query['planner'] ||= {}
        search_query['planner']['resources'] ||= {}
        unless search_query['planner']['resources'].has_key?(name)
          search_query['planner']['resources'][name] ||= {}
          search
        end
      end.on(:resource_removed) do |name|
        search_query['planner'] ||= {}
        search_query['planner']['resources'] ||= {}
        result = search_query['planner']['resources'].delete(name)
        search if result
      end.on(:filter_changed) do |group_name, search_text|
        search_query['planner'] ||= {}
        search_query['planner']['resources'] ||= {}
        search_query['planner']['resources'][group_name] ||= {}
        search_query['planner']['resources'][group_name]['filters'] ||= {}
        resource_klass = klass.reflect_on_association(group_name.to_sym)&.klass
        if resource_klass
          name_attribute = resource_klass.name_attribute
          if search_text.present?
            search_query['planner']['resources'][group_name]['filters'][name_attribute] = { contains: search_text }
          else
            search_query['planner']['resources'][group_name]['filters'].delete(name_attribute)
          end
          search
        end
      end.on(:view_changed) do |interval, view_type, last_date = nil|
        search_query['planner'] ||= {}
        search_query['planner']['view_type'] = view_type
        search_query['planner']['interval'] = interval
        if last_date
          search_query['planner']['last_date'] = last_date
        end
        search
      end.on(:show_event) do |id|
        Dynamic::Form.clear_cache_with_serialized_records
        App.history.push(App.location.add_params(rp: edit_url(klass, id)))
      end.on(:event_dropped) do |elem|
        reload
      end.on(:color_changed) do |resource_id, color|
        save_color_setting(resource_id, color)
      end.on(:unschedule) do
        reload
      end.on(:settings_requested) do
        @show_settings_dialog = true
        mutate
      end
    end

    def reload
      bucket_count if klass_is_configured?
      klass.update_cache([:count])
      super
    end

    def klass_is_configured?
      start_date_attribute.present?
    end

    def bucket_count
      observe @bucket_count = list_filters.count
    end

    def list_filters
      filter = {start_date_attribute => {empty: true}}

      if search_query.dig('planner', 'bucket_filter')
        filter = Crm::Filters::AdvancedList.merge(filter, search_query.dig('planner', 'bucket_filter'))
      end

      return klass.where_filters(filter).includes(include_for_assoc(klass))
    end

    def bucket_filter_present?
      filter = search_query.dig('planner', 'bucket_filter')
      filter.present? && filter.any?
    end

    def update_bucket_width(new_width)
      @bucket_list_width = new_width.to_f
      search_query['planner'] ||= {}
      search_query['planner']['bucket_width'] = @bucket_list_width
      search
    end

    def start_date_attribute
      klass.try(:event_start_date_name)
    end

    def save_color_setting(resource_id, color)
      dynamic_layout do |record|
        element = record.elements.detect{ |e| e.component == 'Crm::Planner' }
        element.component_params[:colors] ||= {}
        previous_color = element.component_params.dig(:colors, resource_id)
        component_params = element.component_params[:colors].merge!(resource_id => color)
        record.update(
          elements_attributes: [
            {
              id: element.id,
              component_params: element.component_params
            }
          ]
        ).then do
          dynamic_layout.stale!
        end.fail do
          if previous_color
            element.component_params[:colors][resource_id] = previous_color
          else
            element.component_params[:colors].delete(resource_id)
          end
          mutate
        end
      end
    end

    def dynamic_layout(&block)
      Dynamic::Layout.where(schema_id: schema.name, klass_name: klass.name).includes(elements: 1).find(layout_id, &block)
    end

    def global_toolbar_right
      Portal(id: 'global-toolbar-right') do
        GroupDrop(maxnum: 3, variant: 'primary') do
          Toolbar::Button(target: new_url(klass), text: I18n.t('shared.new'), icon: 'plus', is_flex: true, "data-open-panel": 'right', variant: 'primary')
          Toolbar::Button(text: I18n.t('shared.refresh'), icon: 'redo', is_flex: true, variant: 'primary').on(:click) do |event|
            event.prevent_default
            reload
          end
          Toolbar::Button(text: I18n.t('crm.edit_query'), icon: 'filter', is_flex: true, target: "#edit_query_dialog", toggle: "modal", variant: 'primary')
          Toolbar::Button(text: I18n.t('crm.reset_filters'), icon: 'filter-circle-xmark', is_flex: true, variant: 'primary').on(:click) do |event|
            event.prevent_default
            reset_filters
          end
          toolbar_import_button
          toolbar_export_button(disabled: true)
          toolbar_delete_button(disabled: true)
        end
        Toolbar::Button(text: '', icon: 'search', is_flex: true, variant: 'primary').on(:click) do |event|
          event.prevent_default
          toggle_search_input
        end
      end
      global_search_input
    end

    def global_toolbar_bottom
      Portal(id: 'global-toolbar-bottom-menu') do
        Crm::BottomPanel(columns_render: 3) do
          BottomPanel::Button(target: '#edit_query_dialog', text: I18n.t('crm.edit_query'), icon: 'filter', toggle: "modal")
          bottom_panel_layout_selector_button
        end
        bottom_panel_layout_selector
      end
    end

    def search_query_defaults
      {
        planner: {
          min_day_time: '08:00:00',
          max_day_time: '18:00:00',
          event_duration: '01:00',
          view_type: 'gantt',
          interval: 'day',
          bucket_width: BUCKET_DEFAULT_WIDTH,
        }
      }
    end

    def effective_resources
      search_query['planner'] ||= {}

      if search_query['planner']['resources'].blank? && resources.present?
        search_query['planner']['resources'] = resources
        search
      end

      search_query['planner']['resources'] || {}
    end

    def resource_ids_from_record(record)
      result = []

      schema_klass = schema.klasses.detect { |k| k.name == record.class.name.demodulize }

      if schema_klass
        schema_klass.attrs.each do |attr|
          next unless attr.type == 'Enum'
          value = record.send(attr.name)
          next unless value
          result << "#{attr.name}-#{value}"
        end
      end

      record.class.reflect_on_all_associations.each do |ref|
        name = ref.name.to_s
        value = record.send(name)
        next unless value
        values = Array(value)
        values.each do |v|
          result << "#{name}-#{v.id}"
        end
      end

      result
    end

    def include_for_assoc(klass)
      includes = {}
      resource_config = search_query.dig('planner', 'resources') || {}
      used_assoc_names = resource_config.keys.map(&:to_s)

      klass.reflect_on_all_associations.each do |ref|
        assoc_name = ref.name.to_s
        next unless used_assoc_names.include?(assoc_name)
        includes[assoc_name] = 1
      end

      includes
    end

    class ParamsConverter < ::Layout::ParamsConverter
      converter_for 'Crm::Planner'

      def apply(params, options = {})
        klass = options.dig(:layout_params, :klass)
        resource_ids = options.dig(:resource_ids)
        converted_resources = {}

        if schema_klass && resource_ids&.any?
          schema_klass.attrs.each do |attr|
            next unless attr.type == 'Enum' && resource_ids.include?(attr.id)
            converted_resources[attr.name] = {}
          end

          schema_klass.associations.each do |assoc|
            next unless resource_ids.include?(assoc.id)
            converted_resources[assoc.name] = {}
          end
        end

        return {
          klass: klass,
          resources: converted_resources,
          timestamp: App.request.object_id
        }
      end

      private

      def schema_klass
        return @schema_klass unless @schema_klass.nil?
        schema = ::Dynamic::Schema.load(App.request.params[:schema])
        @schema_klass = schema.klasses.detect { |k| k.name == App.request.params[:klass].classify }
      end

    end
  end
end