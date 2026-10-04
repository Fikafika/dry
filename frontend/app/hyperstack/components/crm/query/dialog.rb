class Crm
  module Query
    class Dialog < ::Modal

      render { content }

      param :path, default: nil
      param :query, default: nil
      param :record, default: nil # TODO rename current_query
      param :layout_id, default: nil

      fires :apply

      def portal
        'query-modal-portal'
      end

      def body
        DIV(class: 'd-flex flex-row m-n3') do
          next unless ready?
          list_panel
          right_panel
        end
      end

      def title
        if edit_record&.new_record?
          I18n.t('crm.query.new')
        else
          if @edit_record_changed
            "#{I18n.t('crm.query.changed')} *"
          else
            Dynamic::Query::Saved.model_name.human
          end
        end
      end

      def ready?
        path && queries.loaded? && layouts.loaded? && dashboards.loaded?
      end

      # list panel -----------------------------------------------------------------------

      def list_panel
        DIV(class: 'd-flex flex-column border-right position-relative flex-grow-0 flex-shrink-0', style: {width: '200px'}) do
          actions
          if queries.any?
            DIV(class: 'overflow-auto') do
              DIV(class: 'list-group  list-group-flush', style: {maxHeight: max_height}) do
                queries.sort_by {|q| q.human_name || ''}.each do |q|
                  DIV(class: "list-group-item list-group-item-action cursor-pointer #{'active' if selected && q.id == selected.id}", style: {hyphens: 'auto'}) do
                    DIV do
                      q.human_name
                    end
                    if original && q.id == original.id
                      SMALL do
                        Dynamic::Query::Current.model_name.human
                      end
                    end
                  end.on(:click) do |event|
                    event.stop_propagation
                    reset
                    @selected_by_user = true
                    @selected = q.deep_dup
                    @new_record = nil
                    mutate
                  end
                end
              end
            end
          end
          add_button
        end
      end

      def max_height
        'calc(100vh - 250px)'
      end

      def actions
        DIV(class: 'd-flex border-bottom') do
          DIV(class: 'flex-grow-1') do
          end
          DIV(class: 'dropdown') do
            BUTTON(class: "btn btn-transparent-light-yiq shadow-none dropdown-toggle dropdown-toggle-ellipsis", type: "button", 'data-toggle': "dropdown") do
            end
            DIV(class: 'dropdown-menu dropdown-menu-right') do
              A(href: '#delete', class: "dropdown-item text-capitalize-first-letter #{'disabled' unless selected}") do
                I18n.t('shared.delete')
              end.on(:click) do |event|
                event.prevent_default
                event.stop_propagation
                Modal.confirm(title: I18n.t('shared.delete')) do
                  selected.destroy.then do |response|
                    if response["success"]
                      queries.reload do
                        deselect
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end

      def queries
        observe User.current.queries.merge_where(path: path,  type: 'Saved').includes(translations: 1).limit(200).all
      end

      def selected
        return @selected if @selected_by_user
        return if @new_record
        unless @selected
          @selected = original&.deep_dup
          modify if @selected
        end
        return @selected
      end

      def original
        @original ||= queries.detect{|q| q.id == record.original_id } if record&.original_id
      end

      def add_button
        Link('#new', class: "btn btn-primary rounded-circle position-absolute mb-2 mr-3", href: '#new', style: {bottom: 0, right: 0, zIndex: '1000'}) do
          I(class: 'fa fa-plus') {}
        end.on(:click) do |event|
          event.prevent_default
          event.stop_propagation
          reinit
          build_new_record
          mutate
        end
      end

      # right panel -----------------------------------------------------------------------

      def right_panel
        DIV(class: 'd-flex flex-column w-100') do
          if edit_record
            DIV(class: 'pt-3 overflow-auto', style: {maxHeight: max_height}) do
              edit_record.status_code = 200 # for trigger form loaded event
              Form(record: edit_record, class: 'px-3 pb-3') do
                Form::Element::Attribute::String(attribute_name: 'path', editor: 'hidden')
                Form::Element::Attribute::String(attribute_name: 'type', editor: 'hidden')
                Form::Element::Attribute::String(attribute_name: 'user_id', editor: 'hidden')
                Form::Element::Attribute::TranslatableString(attribute_name: 'human_name', auto_focus: true)
                separator
                Form::Element::Attribute::Hash(attribute_name: 'params', mode: 'nested_form') do
                  Form::Element::Attribute::String(attribute_name: 'q', label: I18n.t('crm.query.params.q'))
                  Crm::Query::Table::Filters(attribute_name: 'filters', klass: klass)
                  edit_table
                  edit_kanban
                  edit_planner
                  edit_dashboards
                end
              end.on(:success) do
                edit_record_id = edit_record.id
                queries.reload do
                  reinit
                  @selected = queries.detect{|q| q.id == edit_record_id}
                  @selected_by_user = true
                  mutate
                end
              end.on(:loaded) do |form|
                @form = form
              end.on(:change) do
                mutate @edit_record_changed = true
              end
            end
          end
        end
      end

      def separator
        DIV(class: 'border-top w-100 pb-3') {}
      end

      # table -------------------------------------------------------

      def edit_table
        separator
        H5 { enabled_text(Dynamic::Menu::Item.human_attribute_value(:mode, 'table'), filters_enabled?('table')) }
        Form::Element::Attribute::Hash(attribute_name: 'table', mode: 'nested_form') do
          Crm::Query::Table::Columns(attribute_name: 'columns', klass: klass)
          Crm::Query::Table::Order(attribute_name: 'order', klass: klass)
          Form::Element::Attribute::Hash(
            attribute_name: 'width',
            label: I18n.t('crm.query.params.table.width'),
            label_for_key: Proc.new do |key|
              klass&.datatable_column_by_name.try(:[], key)&.human_path&.join(' > ')
            end,
            hidden_keys: Proc.new do |form|
             (form.submission.params.dig('base', 'params', 'table', 'columns') || []) - (form.submission.params.dig('base', 'params', 'table', 'width')&.keys || [])
            end,
            default_value_for_key: 150,
            values_type: 'number',
            allow_remove: true,
          )
          Form::Element::Attribute::Enum(
            attribute_name: 'locked',
            label: I18n.t('crm.query.params.table.locked'),
            possible_values: Proc.new do |form|
              columns = form.submission.params.dig('base', 'params', 'table', 'columns') || []
              columns.map{|key| {value: key, label: klass&.datatable_column_by_name.try(:[], key)&.human_path&.join(' > ') } }
            end,
          )
          Form::Element::Attribute::Enum(
            attribute_name: 'locked_right',
            label: I18n.t('crm.query.params.table.locked_right'),
            possible_values: Proc.new do |form|
              columns = form.submission.params.dig('base', 'params', 'table', 'columns') || []
              columns.map{|key| {value: key, label: klass&.datatable_column_by_name.try(:[], key)&.human_path&.join(' > ') } }
            end,
          )

          Crm::Query::Table::Summary(attribute_name: 'summary', klass: klass)

        end
      end

      def enabled_text(text, enabled)
        return text if enabled
        "#{text} (#{I18n.t('crm.query.not_applied')})"
      end

      def filters_enabled?(param_key)
        case param_key
        when 'table', 'list'
          if dashboard&.loaded?
            return false
          else
            return true # assume table filters are always used
          end
        when 'kanban'
          return kanban_component.present?
        when /chart\-/
          if dashboard&.loaded?
            id = param_key.split('-').last
            return dashboard.charts.detect{|c| c.id.end_with?(id)}
          else
            return false
          end
        else
          return false
        end
      end

      # kanban -------------------------------------------------------

      def edit_kanban
        return unless kanban_column_attribute.present?
        separator
        H5 { enabled_text(Dynamic::Menu::Item.human_attribute_value(:mode, 'kanban'), filters_enabled?('kanban')) }
        Form::Element::Attribute::Hash(attribute_name: 'kanban', mode: 'nested_form') do
          Crm::Query::Kanban::ColumnStates(attribute_name: 'column_states', klass: klass, column_attribute: kanban_column_attribute)
        end
      end

      def kanban_component
        kanban_components.detect{|e| e.layout_id == layout_id}
      end

      def kanban_column_attribute
        @kanban_column_attribute ||= kanban_components.first&.component_params.try(:[], :column_attribute) # assume one layout with kanban
      end

      def kanban_components
        crm_index_elements.select{|e| e.component == 'Crm::Kanban'}
      end

      # planner ----------------------------------------------------

      def edit_planner
        return unless layout_ids_with_planner.any?
        enabled = layout_ids_with_planner.include?(layout_id)
        separator
        H5{ enabled_text(I18n.t('activerecord.values.dynamic/menu/item.mode.planner'), enabled) }
        Form::Element::Attribute::Hash(attribute_name: 'planner', mode: 'nested_form') do
          Crm::Query::Table::Filters(label: I18n.t('crm.query.params.planner.filter_for_bucket'), attribute_name: 'bucket_filter', klass: klass)
          valid_resources = valid_planner_resources
          if valid_resources.any?
            H6{ I18n.t('crm.query.params.planner.filters_for_resources') }

            Form::Element::Attribute::Hash(attribute_name: 'resources', mode: 'nested_form') do
              valid_resources.each do |resource_name, associated_klass|
                Crm::Query::Table::Filters(attribute_name: resource_name, klass: associated_klass)
              end
            end
          end

          Form::Element::Attribute::TimeOfDay(attribute_name: 'min_day_time', label: I18n.t('crm.query.params.planner.min_day_time'))
          Form::Element::Attribute::TimeOfDay(attribute_name: 'max_day_time', label: I18n.t('crm.query.params.planner.max_day_time'))
          Form::Element::Attribute::TimeOfDay(attribute_name: 'event_duration', label: I18n.t('crm.query.params.planner.event_duration'))
          Form::Element::Attribute::Enum(attribute_name: 'interval', label: I18n.t('crm.query.params.planner.interval'), possible_values: possible_values_for_planner_interval)
          Form::Element::Attribute::Enum(attribute_name: 'view_type', label: I18n.t('crm.query.params.planner.view_type'), possible_values: possible_values_for_planner_view_type)
          Form::Element::Attribute::Date(attribute_name: 'last_date', label: I18n.t('crm.query.params.planner.last_date_viewed'))
        end
      end

      def possible_values_for_planner_interval
        Crm::Planner::View::RESOURCE_GRID_BY_INTERVAL.keys.map { |k| {label: I18n.t("crm.planner.view.interval.#{k}"), value: k} }
      end

      def possible_values_for_planner_view_type
        Crm::Planner::View::VIEW_TYPES.map { |k| {label: I18n.t("crm.planner.view.view_type.#{k}"), value: k} }
      end

      def layout_ids_with_planner
        return [] unless crm_index_elements.loaded?
        crm_index_elements.select {|e| e.component == 'Crm::Planner'}.map(&:layout_id)
      end

      def valid_planner_resources
        resources = query.dig('planner', 'resources')
        return [] unless resources
        resources.keys.filter_map do |resource_name|
          associated_klass = klass.reflect_on_association(resource_name)&.klass
          [resource_name, associated_klass] if associated_klass
        end
      end
      # dashboard ----------------------------------------------------

      def edit_dashboards
        dashboards.each do |d|
          d.charts.sort_by(&:id).each do |chart|
            separator
            H5{ chart_human_name(chart) }
            chart_url_key = ::Crm::Chart::Base.url_id(chart.id)
            Form::Element::Attribute::Hash(attribute_name: chart_url_key, mode: 'nested_form') do
              if chart.type == 'Table'
                Crm::Query::Table::Summary(attribute_name: 'summary', klass: klass, chart_columns: chart.columns)
              else
                Crm::Query::Chart::Order(attribute_name: 'order', klass: klass, chart: chart)
                Crm::Query::Chart::Filter(attribute_name: 'filters',  klass: klass, chart: chart)
              end
              if chart.type != 'Line'
                Crm::Query::Chart::Filter(attribute_name: 'exclusion_filters',  klass: klass, chart: chart)
              end
              Form::Element::Attribute::String(attribute_name: 'contains', label: I18n.t('crm.query.params.chart.contains'))
            end
          end
        end
      end

      def dashboards
        return none unless layouts.loaded? && crm_index_elements.loaded?
        return observe dashboard_klass.with_includes_for_load.where(id: dashboard_ids).all
      end

      def none
        HyperResource::Relation.new
      end

      def dashboard_klass
        "D::#{schema_name}::R::Dashboard".safe_constantize
      end

      def layouts
        observe Dynamic::Layout
          .with_action('index')
          .where(schema_id: schema_name, klass_name: klass.name)
          .all
      end

      def dashboard_ids
        return crm_index_elements.map{|e| e.component_params.try(:[], :record_id)}
      end

      def crm_index_elements
        return none unless layouts.loaded?
        observe @crm_index_elements ||= Dynamic::Layout::Element.where(
          schema_id: schema_id,
          layout_id: layouts.map(&:id),
          klass_id: klass.name.underscore,
          component: ::Crm::Index::Base.subclasses.map(&:name),
        ).all
      end

      def dashboard
        return @dashboard if @dashboard
        dashboard_id = crm_index_elements.detect{|e| e.layout_id == layout_id && e.component == 'Crm::Dashboard'}&.component_params.try(:[], :record_id)
        @dashboard = dashboards.detect{|d| d.id == dashboard_id}
      end

      def chart_human_name(chart)
        if chart.human_name
          chart.human_name
        elsif
          human_type = "Dynamic::Chart::#{chart.type}".safe_constantize.try(:model_name)&.human
          chart_count = 0
          chart.dashboard.charts.each do |c|
            chart_count += 1 if c.type == chart.type
            break if c == chart
          end
          "#{human_type} #{chart_count}"
        end
      end

      # ---------------------------------------------------------------

      def edit_record
        return unless queries.loaded? # must be loaded in order to be sure about selected
        @new_record || selected || build_new_record
      end

      def schema_id
        path =~  /\/crm\/([^\/]+)\//
        $1
      end

      def schema_name
        schema_id.try(:classify_permalink)
      end

      def klass
        path =~  /\/crm\/[^\/]+\/[^\/]+\/([^\/]+)/
        klass_name = $1
        return unless klass_name.present?
        "D::#{schema_name}".safe_constantize&.const_get_by_route_key(klass_name)
      end

      def build_new_record
        @new_record = query_klass.new(path: path, type: 'Saved', params: query.params.deep_dup.except(:l), user_id: User.current.id)
      end

      def query_klass
        "D::#{schema_name}::R::Query::Saved".safe_constantize
      end

      def deselect
        reinit
        mutate
      end

      def reinit
        @new_record = nil
        @selected = nil
        @selected_by_user = nil
        @selected_changed_with_query = nil
        @edit_record_changed = false
        @form&.reset_without_mutate
        @original = nil
      end

      # footer ------------------------------------------------------------------------

      def footer
        unless edit_record&.new_record?
          if @selected_changed_with_query
            BUTTON(key: 'crm.query.dialog.reset', class:"btn bg-light mr-2", type: 'button') do
              I18n.t('crm.query.reset')
            end.on(:click) do |event|
              reset
              mutate
            end
          elsif edit_record && edit_record.params != record.params
            BUTTON(key: 'crm.query.dialog.modify', class:"btn bg-light mr-2", type: 'button') do
              I18n.t('crm.query.replace')
            end.on(:click) do |event|
              modify
              mutate
            end
          end
        end
        BUTTON(key: 'crm.query.dialog.confirm', class:"btn btn-primary", type: 'button', disabled: !confirm_enabled?) do
          confirm_btn_text
        end.on(:click) do |event|
          confirm
        end
        BUTTON(key: 'crm.query.dialog.apply', class: 'btn bg-light mr-2 float-left') do
          I18n.t('shared.apply')
        end.on(:click) do |event|
          update_original_then do
            close(reinit: false)
            apply!(apply_record)
            reinit
          end
        end
      end

      def modify
        @selected_changed_with_query = (query.params != edit_record.params)
        @edit_record_changed = true
        edit_record.params = query.params.deep_dup
        @form&.reset_without_mutate
      end

      def reset
        o = queries.detect{|q| q.id == edit_record.id}
        @selected = o&.deep_dup
        @selected_changed_with_query = false
        @edit_record_changed = false
        @form&.reset_without_mutate
      end

      def confirm_btn_text
        I18n.t('shared.save')
      end

      def confirm
        return unless @form
        if @selected_changed_with_query
          Modal.confirm { submit_form }
        else
          submit_form
        end
      end

      def submit_form
        @form.submit(transform_params: method(:submission_cleaning))
      end

      def submission_cleaning(hash)
        return hash unless hash.has_key?(:params)
        hash[:params] = edit_record.class.clean_params(hash[:params])
        return hash
      end

      def update_original_then
        if record
          record.update(original_id: edit_record.id).then do |response|
            if response[:success]
              yield if block_given?
            else
              puts "error"
            end
          end
        else
          yield if block_given?
        end
      end

      def apply_record
        if @edit_record_changed
          result = edit_record.deep_dup
          result.params = edit_record.class.clean_params(@form.submission.params.dig('base', 'params'))
        else
          result = edit_record.deep_dup
        end
        result.params[:l] = layout_id
        return result
      end

      def close(options = {})
        reinit unless options[:reinit] == false
        super
      end

    private

      def default_size
        'lg'
      end

    end
  end
end
