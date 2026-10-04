# backtick_javascript: true

class Settings
  class Schema
    class Attribute
      class Styles < Attribute::Base

        STYLE_TYPES = {
          'cell_color'   => { name: 'CellColor',   i18n_key: 'settings.attributes.styles.cell_color',   icon: 'fa fa-border-all' },
          'row_color'    => { name: 'RowColor',    i18n_key: 'settings.attributes.styles.row_color',     icon: 'fa fa-align-justify' },
          'badge'        => { name: 'Badge',       i18n_key: 'settings.attributes.styles.badge',                icon: 'fa fa-tag' },
          'icon'         => { name: 'Icon',        i18n_key: 'settings.attributes.styles.icon',                icon: 'fa fa-icons' },
          'progress_bar' => { name: 'ProgressBar', i18n_key: 'settings.attributes.styles.progress_bar', icon: 'fa fa-tasks' },
          'button'       => { name: 'Button',      i18n_key: 'settings.attributes.styles.button',       icon: 'fa fa-hand-pointer' },
        }.freeze

        render { content }

        def klass
          nil
        end

        def self.resources_name(klass = nil)
          'styles'
        end

        def current_type
          request.params['type']
        end

        def current_config
          return {} unless current_type
          STYLE_TYPES[current_type] || {}
        end

        def current_model
          return new_record if is_new_record?
          style_concern
        end

        def is_new_record?
          match.params[:id] == 'new'
        end

        def new_record
          style_concern || OpenStruct.new(id: 'new', type: current_type)
        end

        def parent_parent_page(params = {})
          CollectionPage(
            klass: Dynamic::Schema::Attribute::Base,
            resource_id_key: :attr_id,
            path_prefix: path_prefix,
            location: attrs_location,
            location_suffix: parent_parent_location_suffix,
            scope_for_all: {schema_id: match.params[:schema_id], klass_id: match.params[:klass_id]},
          )
        end

        def attr_page(params = {})
          ::Stackable::Page() do
            ::Stackable::Toolbar() do
              ::Stackable::PageHeader(title: schema_attr.human_name, back: attrs_location)
            end
            ::Stackable::List({
              active: 'styles',
              items: items,
              location: back_location
            })
          end
        end

        def list_page
          return feature_disabled_page unless style_feature_enabled?
          if current_type.present?
            StylesCollectionPage(
              klass: ::Dynamic::Schema::Attribute::Base,
              schema: schema,
              schema_klass: schema_klass,
              schema_attr: schema_attr,
              concern: style_concern,
              rules: filtered_rules,
              location: index_location,
              current_type: current_type,
              config: current_config,
              editable: true,
            )
          else
            StylesTypesPage(
              schema: schema,
              schema_klass: schema_klass,
              schema_attr: schema_attr,
              location: index_location,
            )
          end
        end

        def feature_disabled_page
          ::Stackable::Page() do
            ::Stackable::Toolbar() do
              ::Stackable::PageHeader(title: schema_attr.human_name, back: attrs_location)
            end
            DIV(class: 'p-4') do
              DIV(class: 'alert alert-warning') do
                I(class: 'fa fa-exclamation-triangle mr-2')
                I18n.t('settings.attributes.styles.feature_disabled')
              end
            end
          end
        end

        def edit_panel
          EditPanel(
            path: "#{index_location}/:id",
            record: current_model,
            concern: style_concern,
            schema: schema,
            schema_klass: schema_klass,
            schema_attr: schema_attr,
            rule_index: rule_index_from_params,
            all_rules: all_rules_from_concern,
            is_new_rule: is_new_record? && request.params['edit_rule'].blank?,
            style_type: current_type,
            style_config: current_config,
            back_location: back_location_with_type
          )
        end

        def rule_index_from_params
          edit_idx = request.params['edit_rule']
          if edit_idx.present?
            edit_idx.to_i
          elsif is_new_record?
            next_rule_index
          else
            (match.params[:id] || 0).to_i
          end
        end

        def back_location_with_type
          "#{index_location}?type=#{current_type}"
        end

        def next_rule_index
          all_rules = all_rules_from_concern
          all_rules.empty? ? 0 : (all_rules.map { |r| r[:index] }.compact.max || -1) + 1
        end

        def style_feature_enabled?
          return false unless schema
          schema.has_feature_enabled?('Dynamic::Datatable::Style::Feature')
        rescue
          false
        end

        def style_feature
          return nil unless schema
          schema.features.detect { |f| f.name == 'Dynamic::Datatable::Style::Feature' }
        rescue
          nil
        end

        def style_concern
          return nil unless current_type
          return nil if current_config.empty?
          return nil unless schema_klass&.id
          cache_key = "@style_concern_#{current_type}"
          return instance_variable_get(cache_key) if instance_variable_defined?(cache_key)
          feature = style_feature
          return nil unless feature
          concern_name = current_config[:name]
          return nil unless concern_name
          existing = feature.concerns.detect do |c|
            c.name == concern_name && c.klass_id == schema_attr&.klass_id
          end
          result = existing || create_style_concern(feature, concern_name)
          instance_variable_set(cache_key, result)
          result
        end

        def create_style_concern(feature, concern_name)
          return nil unless feature
          return nil unless schema_klass

          config = STYLE_TYPES.values.detect { |v| v[:name] == concern_name }
          attrs = {
            klass_id: schema_attr&.klass_id,
            name: concern_name,
            type: 'Dynamic::Schema::Concern',
            template: false
          }
          if config
            I18n.available_locales.each do |locale|
              attrs[:"human_name_#{locale}"] = I18n.t(config[:i18n_key], locale: locale)
            end
          else
            attrs[:human_name] = concern_name
          end
          feature.concerns.create(attrs)
        end

        def all_rules_from_concern
          return [] unless style_concern
          extract_rules_from_options(style_concern.options.to_a)
        end

        def filtered_rules
          attr_id = schema_attr&.id.to_s
          all_rules_from_concern.select do |rule|
            rule[:attr_id].to_s == attr_id
          end
        end

        def extract_rules_from_options(options)
          rule_indices = []
          options.each do |opt|
            if opt.name =~ /^rule_\w+_(\d+)$/
              rule_indices << $1.to_i
            end
          end

          rule_indices.uniq.sort.map do |idx|
            conditions = options.detect { |o| o.name == "rule_conditions_#{idx}" }&.value
            {
              index: idx,
              attr_id: options.detect { |o| o.name == "rule_attr_id_#{idx}" }&.value,
              conditions: conditions.is_a?(Array) ? conditions : [],
              is_default: options.detect { |o| o.name == "rule_is_default_#{idx}" }&.value,
              default_style_css: options.detect { |o| o.name == "rule_default_style_css_#{idx}" }&.value,
              default_style_icon: options.detect { |o| o.name == "rule_default_style_icon_#{idx}" }&.value,
              min_value: options.detect { |o| o.name == "rule_min_value_#{idx}" }&.value,
              max_value: options.detect { |o| o.name == "rule_max_value_#{idx}" }&.value,
              show_label: options.detect { |o| o.name == "rule_show_label_#{idx}" }&.value,
              default_css_class: options.detect { |o| o.name == "rule_default_css_class_#{idx}" }&.value,
              default_icon_class: options.detect { |o| o.name == "rule_default_icon_class_#{idx}" }&.value,
            }
          end
        end


        def available_attributes_for_condition
          return [] unless schema_klass
          attrs = []
          if schema_klass.respond_to?(:attrs) && schema_klass.attrs
            schema_klass.attrs.each do |attr|
              attrs << { id: attr.id, name: attr.name, human_name: attr.human_name, type: 'attr' }
            end
          end
          if schema_klass.respond_to?(:associations) && schema_klass.associations
            schema_klass.associations.each do |assoc|
              attrs << { id: assoc.id, name: assoc.name, human_name: assoc.human_name, type: 'assoc' }
            end
          end
          attrs.sort_by { |a| a[:human_name] || a[:name] }
        end

        class StylesTypesPage < ::Stackable::Page

          param :schema, default: nil
          param :schema_klass, default: nil
          param :schema_attr, default: nil
          param :location, default: nil

          render { content }

          def content
            layout do
              ::Stackable::Toolbar() do
                ::Stackable::PageHeader(title: I18n.t('settings.attributes.styles.title'))
              end
              DIV(class: 'flex-grow-1 overflow-auto') do
                style_keys = STYLE_TYPES.keys
                STYLE_TYPES.each do |key, config, idx|
                  target_url = "#{location}?type=#{key}"
                  label = I18n.t(config[:i18n_key]).presence || config[:name]
                  A(href: target_url, class: 'text-decoration-none') do
                    DIV(class: "d-flex align-items-center px-3 py-3 list-group-item-action #{ ' border-bottom' unless idx == style_keys.size - 1}") do
                      I(class: "#{config[:icon]} fa-2x mr-3")
                      DIV do
                        SPAN(class: 'd-block') { label }
                        SMALL(class: 'text-muted') { I18n.t('settings.attributes.styles.edit_rule', label: label.to_s.downcase)}
                      end
                    end
                  end.on(:click) do |e|
                    e.prevent_default
                    App.history.push(target_url)
                  end
                end
              end
            end
          end
        end

        class StylesCollectionPage < ::Stackable::Page

          param :klass, default: NilClass
          param :schema, default: nil
          param :schema_klass, default: nil
          param :schema_attr, default: nil
          param :concern, default: nil
          param :rules, default: []
          param :location, default: nil
          param :current_type, default: nil
          param :config, default: {}
          param :editable, default: true

          render { content }

          def list_title
            "#{I18n.t('settings.attributes.styles.title')}"
          end

          def back_location
            location.split('?')[0]
          end

          def models
            rules || []
          end

          def resource_id
            @resource_id ||= request.params[:id]
          end

          def model_to_item(rule)
            return nil unless rule.is_a?(Hash)
            first_condition = rule[:conditions].is_a?(Array) ? rule[:conditions].first : nil
            first_css = first_condition&.dig('css_class')
            type_config = STYLE_TYPES[current_type] || {}
            display_icon = type_config[:icon] || 'fa fa-check'
            display_badge = 'bg-light text-dark'
            case current_type
            when 'icon'
            when 'progress_bar'
              display_badge = first_css || 'bg-primary'
            when 'button'
              display_badge = first_css || 'btn-primary'
            when 'badge', 'cell_color', 'row_color'
              display_badge = first_css || 'bg-secondary'
            end
            {
              id: rule[:index].to_s,
              icon: display_icon,
              title: build_condition_text(rule),
              badge_class: display_badge,
              path: "#{location}/new?type=#{current_type}&edit_rule=#{rule[:index]}"
            }
          end

          def build_condition_text(rule)
            if rule[:conditions].is_a?(Array) && rule[:conditions].any?
              return "#{rule[:conditions].size} #{I18n.t('settings.attributes.styles.count_rule')}"
            end
            if current_type == 'progress_bar'
              min_val = rule[:min_value] || 0
              max_val = rule[:max_value] || 100
              return "#{min_val} - #{max_val}"
            end
            ''
          end

          def items
            models.map { |model| model_to_item(model) }.compact
          end

          def current_model
            return nil unless resource_id
            models.detect { |r| r[:index].to_s == resource_id.to_s }
          end

          def current_item
            return nil unless resource_id
            rule = models.detect { |r| r[:index].to_s == resource_id.to_s }
            model_to_item(rule)
          end

          def content
            layout do
              ::Stackable::Toolbar() do
                ::Stackable::PageHeader(title: list_title, back: back_location) do
                end
              end
              if items.empty?
                DIV(class: 'p-4 text-center text-muted flex-grow-1 d-flex flex-column justify-content-center') do
                  I(class: 'fa fa-inbox fa-3x mb-3 d-block')
                  SPAN { I18n.t('settings.attributes.styles.nothing_rule') }
                end
              else
                ::Stackable::List({
                  active: current_item.try(:[], :id),
                  items: items,
                  location: location
                })
              end
              add_button if editable && items.empty?
            end
          end

          def add_button
            ::Stackable::AddButton(href: "#{location}/new?type=#{current_type}")
          end
        end

        class EditPanel < ::Settings::Schema::EditPanel

          render { content }

          param :schema, default: nil
          param :schema_klass, default: nil
          param :schema_attr, default: nil
          param :concern, default: nil
          param :rule_index, default: 0
          param :all_rules, default: []
          param :is_new_rule, default: false
          param :style_type, default: 'cell_color'
          param :style_config, default: {}
          param :back_location, default: nil

          before_mount do
            @saving = false
            load_rule_data
          end

          def load_rule_data
            @use_multiple_conditions = true
            @use_different_condition_attr = false
            @condition_attr_id = nil
            @cond = '='
            @color = default_color
            @value = ''
            @icon_class = ''
            @min_value = 0
            @max_value = 100
            @show_label = true
            @conditions = []
            @default_btn_css = 'btn-primary'
            @default_btn_icon = ''
            @is_default = false
            @default_style_css = default_color
            @default_style_icon = ''

            return if is_new_rule

            rule = all_rules.detect { |r| r[:index] == rule_index && r[:attr_id].to_s == schema_attr&.id.to_s }
            rule ||= all_rules.detect { |r| r[:attr_id].to_s == schema_attr&.id.to_s }
            return unless rule

            @effective_rule_index = rule[:index]
            @is_default = (rule[:is_default] == true || rule[:is_default].to_s == 'true') ? true : false
            @default_style_css = rule[:default_style_css] || default_color
            @default_style_icon = rule[:default_style_icon] || ''

            if rule[:conditions].is_a?(Array) && rule[:conditions].any?
              @conditions = rule[:conditions]
              first_cond = @conditions.first
              @condition_attr_id = first_cond['condition_attr_id'] if first_cond
              @use_different_condition_attr = @condition_attr_id.present?
            end

            @min_value = (rule[:min_value] || 0).to_i
            @max_value = (rule[:max_value] || 100).to_i
            @show_label = rule[:show_label].to_s == 'true'
            @default_btn_css  = rule[:default_css_class] || 'btn-primary'
            @default_btn_icon = rule[:default_icon_class] || ''
          end

          def available_attrs
            return [] unless schema_klass
            attrs = []
            if schema_klass.respond_to?(:attrs) && schema_klass.attrs
              schema_klass.attrs.each do |attr|
                attrs << { id: attr.id.to_s, name: attr.name, human_name: attr.human_name }
              end
            end
            attrs.sort_by { |a| a[:human_name] || a[:name] }
          end

          def default_color
            case style_type
            when 'badge' then 'badge-primary'
            when 'icon' then ''
            when 'progress_bar' then 'bg-primary'
            when 'button' then 'btn-primary'
            else ''
            end
          end

          def content
            panel_layout do
              header
              container do
                form_content
              end
              footer
            end
          end

          def panel_layout
            DIV class: 'd-flex flex-column h-100' do
              yield
            end
          end

          def container
            DIV(class: 'container-fluid d-flex flex-column pt-3 flex-grow-1', style: {overflowY: 'auto', overflowX: 'hidden'}) do
              yield
            end
          end

          def invalidate_current_style_cache
            cache_key = "@style_concern_#{style_type}"
            remove_instance_variable(cache_key) if instance_variable_defined?(cache_key)
          end

          def manual_trigger_klass
            return @_mt_klass if @_mt_resolved
            @_mt_resolved = true
            parent_mod = schema&.const || schema_klass&.const&.parent
            @_mt_klass = "#{parent_mod.name}::R::Workflow::ManualTrigger".safe_constantize if parent_mod
          end

          def manual_triggers
            return [] unless manual_trigger_klass
            observe triggers = manual_trigger_klass.all
            triggers.sort_by { |t| t.id }
          end

          def header
            ::Stackable::Toolbar() do
              ::Stackable::PageHeader(title: I18n.t('settings.attributes.styles.edit_rule', label: concern.human_name.downcase)) do
                action_menu unless is_new_rule
              end
            end
          end

          def action_menu
            DIV(class: 'dropdown') do
              BUTTON(class: "btn btn-transparent-light-yiq shadow-none dropdown-toggle dropdown-toggle-ellipsis", type: "button", 'data-toggle': "dropdown") do
              end
              DIV(class: 'dropdown-menu dropdown-menu-right') do
                item_delete
              end
            end
          end

          def item_delete
            A(href: '#', class: 'dropdown-item') do
              I18n.t('shared.delete')
            end.on(:click) do |event|
              event.prevent_default
              Modal.confirm(title: I18n.t('shared.delete')) do
                delete_concern
              end
            end
          end

          def delete_concern
            return unless concern
            @conditions = []
            mutate

            attr_id = schema_attr&.id.to_s
            del_rule_indices = all_rules.select { |r| r[:attr_id].to_s == attr_id }.map { |r| r[:index] }
            other_rules = all_rules.reject { |r| r[:attr_id].to_s == attr_id }
            if other_rules.empty?
              invalidate_current_style_cache
              concern.destroy.then do |res|
                concern.options.load.then do
                  App.history.replace(back_location.split('?').first)
                end
              end
            else
              options_to_update = concern.options.map do |opt|
                option_data = { id: opt.id, name: opt.name, value: opt.value, type: opt.type || 'String' }
                del_rule_indices.each do |idx|
                  option_data[:_destroy] = '1' if opt.name =~ /^rule_\w+_#{idx}$/
                end
                option_data
              end
              invalidate_current_style_cache
              concern.update(options_attributes: options_to_update).then do |res|
                concern.options.load.then do
                  App.history.replace(back_location.split('?').first)
                end
              end
            end
          end

          def form_content
            if style_type == 'progress_bar'
              render_progress_bar_fields
            elsif style_type == 'button'
              render_button_fields
            else
              render_condition_fields
            end
          end

          def render_progress_bar_fields
            DIV(class: 'row') do
              DIV(class: 'col-md-6 mb-3') do
                LABEL(class: 'form-label') { I18n.t('settings.attributes.styles.min_value') }
                INPUT(type: 'number', class: 'form-control', value: @min_value).on(:change) do |e|
                  @min_value = e.target.value.to_i
                  mutate
                end
              end
              DIV(class: 'col-md-6 mb-3') do
                LABEL(class: 'form-label') { I18n.t('settings.attributes.styles.max_value') }
                INPUT(type: 'number', class: 'form-control', value: @max_value).on(:change) do |e|
                  @max_value = e.target.value.to_i
                  mutate
                end
              end
            end

            DIV(class: 'mb-3') do
              DIV(class: 'form-check') do
                INPUT(type: 'checkbox', class: 'form-check-input', id: 'show_label', checked: @show_label).on(:change) do |e|
                  @show_label = e.target.checked
                  mutate
                end
                LABEL(class: 'form-check-label') { I18n.t('settings.attributes.styles.show_label') }
              end
            end

            if @conditions.empty?
              @conditions = [{
                'operator' => '',
                'value' => '',
                'css_class' => 'bg-primary',
                'condition_attr_id' => ''
              }]
            end

            @conditions.each_with_index do |condition, idx|
              render_progress_bar_condition_item(condition, idx)
            end

            DIV(class: 'mt-3 text-right') do
              BUTTON(class: 'btn btn-transparent-light-yiq') do
                I(class: 'fa fa-plus mr-1')
                I18n.t('settings.attributes.styles.add_rule')
              end.on(:click) do
                @conditions << {
                  'operator' => '',
                  'value' => '',
                  'css_class' => '',
                  'condition_attr_id' => ''
                }
                mutate
              end
            end
          end

          def render_progress_bar_condition_item(condition, idx)
            DIV(class: 'card mb-2') do
              DIV(class: 'card-body p-3') do
                DIV(class: 'd-flex justify-content-end align-items-center mb-2') do
                  if @conditions.size > 1
                    BUTTON(class: 'btn btn-sm btn-transparent-light-yiq shadow-none') do
                      I(class: 'fa fa-trash')
                    end.on(:click) do
                      delete_condition(idx)
                    end
                  end
                end

                DIV(class: 'row') do
                  DIV(class: 'col mb-2') do
                    LABEL { I18n.t('settings.attributes.styles.rule') }
                    SELECT(class: 'form-control', value: condition['operator'] || '') do
                      OPTION(value: '') { "" }
                      progress_operator_options.each do |op|
                        OPTION(value: op[:value]) { I18n.t(op[:i18n_key]) }
                      end
                    end.on(:change) do |e|
                      @conditions[idx]['operator'] = e.target.value
                      mutate
                    end
                  end

                  DIV(class: 'col mb-2') do
                    LABEL  { I18n.t('settings.attributes.styles.value') }
                    INPUT(
                      type: 'number',
                      class: 'form-control',
                      value: condition['value'] || '',
                    ).on(:change) do |e|
                      @conditions[idx]['value'] = e.target.value
                      mutate
                    end
                  end

                  DIV(class: 'col mb-2') do
                    LABEL  { I18n.t('settings.attributes.styles.color') }
                    CssClassSelector(
                      value: condition['css_class'] || default_color,
                      style_type: style_type,
                    ).on(:change) do |val|
                      @conditions[idx]['css_class'] = val
                      mutate
                    end
                  end
                end
              end
            end
          end

          def render_button_fields
            if @conditions.empty?
              @conditions = [{
                'operator' => '*=',
                'value' => '',
                'css_class' => 'btn-primary',
                'icon_class' => ''
              }]
            end

            DIV(class: 'mb-3') do
              LABEL(class: 'form-label font-weight-bold') { I18n.t('settings.attributes.styles.button_style_rules') }
            end

            @conditions.each_with_index do |condition, idx|
              render_button_style_rule(condition, idx)
            end

            DIV(class: 'mt-3 text-right') do
              BUTTON(class: 'btn btn-transparent-light-yiq') do
                I(class: 'fa fa-plus mr-1')
                I18n.t('settings.attributes.styles.add_rule')
              end.on(:click) do
                @conditions << {
                  'operator' => '*=',
                  'value' => '',
                  'css_class' => 'btn-primary',
                  'icon_class' => ''
                }
                mutate
              end
            end

            HR()

            DIV(class: 'mb-3') do
              LABEL(class: 'form-label font-weight-bold') { I18n.t('settings.attributes.styles.button_defaults') }
            end

            DIV(class: 'row') do
              DIV(class: 'col-md-6 mb-2') do
                LABEL { I18n.t('settings.attributes.styles.default_color') }
                CssClassSelector(
                  value: @default_btn_css || 'btn-primary',
                  style_type: 'button',
                ).on(:change) do |val|
                  @default_btn_css = val
                  mutate
                end
              end
              DIV(class: 'col-md-6 mb-2') do
                LABEL { I18n.t('settings.attributes.styles.default_icon') }
                INPUT(class: 'form-control', value: @default_btn_icon || '', placeholder: 'fa fa-play').on(:change) do |e|
                  @default_btn_icon = e.target.value
                  mutate
                end
              end
            end
          end

          def render_button_style_rule(condition, idx)
            DIV(class: 'card mb-2') do
              DIV(class: 'card-body p-3') do
                DIV(class: 'd-flex justify-content-end align-items-center mb-2') do
                  if @conditions.size > 1
                    BUTTON(class: 'btn btn-sm btn-transparent-light-yiq shadow-none') do
                      I(class: 'fa fa-trash')
                    end.on(:click) do
                      delete_condition(idx)
                    end
                  end
                end

                DIV(class: 'row') do
                  DIV(class: 'col-md-2 mb-2') do
                    LABEL { I18n.t('settings.attributes.styles.operator') }
                    SELECT(class: 'form-control', value: condition['operator'] || '*=') do
                      OPTION(value: '*=') { I18n.t('settings.attributes.styles.contains') }
                      OPTION(value: '=')  { I18n.t('settings.attributes.styles.equals') }
                    end.on(:change) do |e|
                      @conditions[idx]['operator'] = e.target.value
                      mutate
                    end
                  end

                  DIV(class: 'col-md-3 mb-2') do
                    LABEL { I18n.t('settings.attributes.styles.trigger_name_pattern') }
                    INPUT(
                      type: 'text',
                      class: 'form-control',
                      value: condition['value'] || '',
                      placeholder: I18n.t('settings.attributes.styles.trigger_name_contains_placeholder')
                    ).on(:change) do |e|
                      @conditions[idx]['value'] = e.target.value
                      mutate
                    end
                  end

                  DIV(class: 'col-md-3 mb-2') do
                    LABEL { I18n.t('settings.attributes.styles.color') }
                    CssClassSelector(
                      value: condition['css_class'] || 'btn-primary',
                      style_type: 'button',
                    ).on(:change) do |val|
                      @conditions[idx]['css_class'] = val
                      mutate
                    end
                  end

                  DIV(class: 'col-md-4 mb-2') do
                    LABEL { I18n.t('settings.attributes.styles.icon') }
                    INPUT(
                      class: 'form-control',
                      value: condition['icon_class'] || '',
                      placeholder: 'fa fa-paper-plane'
                    ).on(:change) do |e|
                      @conditions[idx]['icon_class'] = e.target.value
                      mutate
                    end
                  end
                end

                DIV(class: 'mt-2 pt-2 border-top') do
                  SMALL(class: 'text-muted mr-2') { I18n.t('settings.attributes.styles.preview') }
                  render_condition_preview(condition)
                end
              end
            end
          end

          def render_condition_fields
            unless style_type == 'row_color'
              DIV(class: 'mb-3') do
                DIV(class: 'form-check') do
                  checkbox_attrs = {
                    type: 'checkbox',
                    class: 'form-check-input',
                    id: 'is_default_style',
                    checked: !!@is_default,
                  }
                  INPUT(**checkbox_attrs).on(:change) do |e|
                    @is_default = e.target.checked
                    mutate
                  end
                  LABEL(class: 'form-check-label') do
                    I18n.t('settings.attributes.styles.default_style')
                  end
                  SMALL(class: 'form-text text-muted d-block') do
                    I18n.t('settings.attributes.styles.default_style_hint')
                  end
                end
              end
              if @is_default
                render_default_style_fields
              end
            end
            if @conditions.empty? && !@is_default
              @conditions = [{
                'operator' => @cond || '=',
                'value' => @value || '',
                'css_class' => @color || default_color,
                'icon_class' => @icon_class || '',
                'condition_attr_id' => @condition_attr_id || ''
              }]
            end
            render_multiple_conditions if @conditions.any? || !@is_default
          end

          def render_default_style_fields
            DIV(class: 'card mb-3') do
              DIV(class: 'card-body p-3') do
                LABEL(class: 'font-weight-bold mb-2 d-block') do
                  I18n.t('settings.attributes.styles.default_appearance')
                end
                DIV(class: 'row') do
                  DIV(class: 'col mb-2') do
                    LABEL { color_label_for_type }
                    CssClassSelector(
                      value: @default_style_css || default_color,
                      style_type: style_type,
                    ).on(:change) do |val|
                      @default_style_css = val
                      mutate
                    end
                  end

                  if style_type == 'icon'
                    DIV(class: 'col mb-2') do
                      LABEL { I18n.t('settings.attributes.styles.icon') }
                      INPUT(
                        class: 'form-control',
                        value: @default_style_icon || '',
                        placeholder: 'fas fa-circle'
                      ).on(:change) do |e|
                        @default_style_icon = e.target.value
                        mutate
                      end
                    end
                  end
                end
                DIV(class: 'mt-2 pt-2 border-top') do
                  SMALL(class: 'text-muted mr-2') { I18n.t('settings.attributes.styles.preview') }
                  render_default_preview
                end
              end
            end
            if @conditions.any?
              DIV(class: 'mb-2') do
                LABEL(class: 'font-weight-bold') do
                  I18n.t('settings.attributes.styles.exceptions')
                end
                SMALL(class: 'form-text text-muted d-block mb-2') do
                  I18n.t('settings.attributes.styles.exceptions_hint')
                end
              end
            end
          end

          def render_default_preview
            css_class = @default_style_css || default_color
            case style_type
            when 'badge'
              SPAN(class: "badge #{css_class}") { I18n.t('settings.attributes.styles.preview_text') }
            when 'icon'
              icon = @default_style_icon || 'fas fa-circle'
              SPAN(class: css_class) do
                I(class: "#{icon} mr-1")
                SPAN(class: 'small') { I18n.t('settings.attributes.styles.preview_text') }
              end
            when 'cell_color'
              SPAN(class: "px-2 py-1 #{css_class} rounded", style: { fontSize: '12px' }) do
                I18n.t('settings.attributes.styles.cell')
              end
            else
              SPAN(class: "px-2 py-1 #{css_class} rounded", style: { fontSize: '12px' }) { I18n.t('settings.attributes.styles.preview_text') }
            end
          end

          def render_multiple_conditions
            DIV(class: 'multiple-conditions-editor') do
              @conditions.each_with_index do |condition, idx|
                render_condition_item(condition, idx)
              end

              DIV(class: 'mt-3 text-right') do
                BUTTON(class: 'btn btn-transparent-light-yiq') do
                  I(class: 'fa fa-plus mr-1')
                  I18n.t('settings.attributes.styles.add_rule')
                end.on(:click) do
                  @conditions << {
                    'operator' => '=',
                    'value' => '',
                    'css_class' => default_color,
                    'condition_attr_id' => ''
                  }
                  mutate
                end
              end
            end
          end

          def render_condition_item(condition, idx)
            DIV(class: 'card mb-2') do
              DIV(class: 'card-body p-3') do
                DIV(class: 'd-flex justify-content-end align-items-center mb-2') do
                  BUTTON(class: 'btn btn-sm btn-transparent-light-yiq shadow-none') do
                    I(class: 'fa fa-trash')
                  end.on(:click) do
                    delete_condition(idx)
                  end
                end
                DIV(class: 'row') do
                  DIV(class: 'col mb-2') do
                    LABEL { I18n.t('settings.attributes.styles.target_column') }
                    SELECT(class: 'form-control', value: condition['condition_attr_id'] || '') do
                      OPTION(value: '') { I18n.t('settings.attributes.styles.target_column') }
                      available_attrs.each do |attr|
                        OPTION(value: attr[:id]) { attr[:human_name] || attr[:name] }
                      end
                    end.on(:change) do |e|
                      selected_id = e.target.value
                      @conditions[idx]['condition_attr_id'] = selected_id
                      mutate
                    end
                  end

                  DIV(class: 'col mb-2') do
                    LABEL { I18n.t('settings.attributes.styles.operator') }
                    SELECT(class: 'form-control', value: condition['operator'] || '=') do
                      operator_options.each do |op|
                        OPTION(value: op[:value]) { I18n.t(op[:i18n_key]) }
                      end
                    end.on(:change) do |e|
                      @conditions[idx]['operator'] = e.target.value
                      mutate
                    end
                  end

                  unless ['∅', '!∅'].include?(condition['operator'])
                    DIV(class: 'col mb-2') do
                      LABEL { I18n.t('settings.attributes.styles.value') }
                      INPUT(
                        type: 'text',
                        class: 'form-control',
                        value: condition['value'] || '',
                      ).on(:change) do |e|
                        @conditions[idx]['value'] = e.target.value
                        mutate
                      end
                    end
                  end
                  DIV(class: 'col mb-2') do
                    LABEL { color_label_for_type }
                    CssClassSelector(
                      value: condition['css_class'] || default_color,
                      style_type: style_type,
                    ).on(:change) do |val|
                      @conditions[idx]['css_class'] = val
                      mutate
                    end
                  end
                  if style_type == 'icon'
                    DIV(class: 'col mb-2') do
                      LABEL { I18n.t('settings.attributes.styles.icon') }
                      INPUT(class: 'form-control', value: condition['icon_class']).on(:change) do |e|
                        @conditions[idx]['icon_class'] = e.target.value
                        mutate
                      end
                    end
                  end
                end

                DIV(class: 'mt-2 pt-2 border-top') do
                  SMALL(class: 'text-muted mr-2') { I18n.t('settings.attributes.styles.preview') }
                  render_condition_preview(condition)
                end
              end
            end
          end

          def color_label_for_type
            case style_type
            when 'badge' then I18n.t('settings.attributes.styles.color')
            else I18n.t('settings.attributes.styles.color')
            end
          end

          def render_condition_preview(condition)
            css_class = condition['css_class'] || default_color
            icon_class = condition['icon_class'] || ''
            case style_type
            when 'badge'
              SPAN(class: "badge #{css_class}") { condition['value'] || '' }
            when 'icon'
              SPAN(class: css_class) do
                I(class: "#{icon_class} mr-1")
                SPAN(class: 'small') { condition['value'] || '' }
              end
            when 'button'
              op = condition['operator'] || '*='
              val = condition['value'] || ''
              label = if val.present?
                op == '=' ? val : "...#{val}..."
              else
                I18n.t('settings.attributes.styles.trigger_name_pattern')
              end
              A(class: "btn btn-sm #{css_class}", href: '#') do
                I(class: "#{icon_class} mr-1") if icon_class.present?
                SPAN { label }
              end
            when 'row_color'
              SPAN(class: "px-2 py-1 #{css_class} rounded", style: { fontSize: '12px' }) { I18n.t('settings.attributes.styles.row') }
            else
              SPAN(class: "px-2 py-1 #{css_class} rounded", style: { fontSize: '12px' }) { I18n.t('settings.attributes.styles.cell') }
            end
          end

          def footer
            DIV(class: 'p-3 d-flex justify-content-end') do
              BUTTON(class: 'btn btn-light mr-2') do
                I18n.t('shared.cancel')
              end.on(:click) { App.history.push(back_location) }
              BUTTON(class: 'btn btn-primary', disabled: @saving) do
                I18n.t('shared.save')
              end.on(:click) { save_rule }
            end
          end

          def save_rule
            if @effective_rule_index
              update_existing_rule
            else
              create_new_rule
            end
          end

          def effective_rule_index
            @effective_rule_index || rule_index
          end

          def delete_condition(idx)
            @conditions.delete_at(idx)
            if @conditions.empty?
              destroy_rule_and_maybe_concern
            else
              mutate
            end
          end

          def destroy_rule_and_maybe_concern
            return unless concern
            other_rules = all_rules.reject { |r| r[:index] == rule_index }
            if other_rules.empty?
              concern.destroy.then do |res|
                App.history.replace(back_location.split('?').first)
              end
            else
              options_to_update = concern.options.map do |opt|
                option_data = { id: opt.id, name: opt.name, value: opt.value, type: opt.type || 'String' }
                option_data[:_destroy] = '1' if opt.name =~ /^rule_\w+_#{rule_index}$/
                option_data
              end
              concern.update(options_attributes: options_to_update).then do |res|
                App.history.replace(back_location)
              end
            end
          end

          def create_new_rule
            return unless concern
            @saving = true
            mutate
            used_indices = all_rules.filter_map { |o| o[:index] }
            current_rule_index = used_indices.empty? ? 0 : used_indices.max + 1
            attr_id = schema_attr.id.to_s
            new_options = [
              { name: "rule_attr_id_#{current_rule_index}", value: attr_id, type: 'String' },
              { name: "rule_conditions_#{current_rule_index}", value: @conditions, type: 'Array' },
              { name: "rule_is_default_#{current_rule_index}", value: @is_default.to_s, type: 'Boolean' },
              { name: "rule_default_style_css_#{current_rule_index}", value: @default_style_css, type: 'String' },
              { name: "rule_default_style_icon_#{current_rule_index}", value: @default_style_icon, type: 'String' },
            ]
            if style_type == 'progress_bar'
              new_options += [
                { name: "rule_min_value_#{current_rule_index}", value: @min_value.to_s, type: 'Integer' },
                { name: "rule_max_value_#{current_rule_index}", value: @max_value.to_s, type: 'Integer' },
                { name: "rule_show_label_#{current_rule_index}", value: @show_label.to_s, type: 'Boolean' },
              ]
            end
            if style_type == 'button'
              new_options += [
                { name: "rule_default_css_class_#{current_rule_index}", value: @default_btn_css || 'btn-primary', type: 'String' },
                { name: "rule_default_icon_class_#{current_rule_index}", value: @default_btn_icon || '', type: 'String' },
              ]
            end

            concern.update(options_attributes: new_options).then do |response|
              @effective_rule_index = current_rule_index
              mutate @saving = false
            end
          end

          def update_existing_rule
            return unless concern
            return if @saving
            mutate @saving = true
            idx = effective_rule_index
            options_to_update = concern.options.map do |opt|
              data = { id: opt.id, name: opt.name, value: opt.value, type: opt.type || 'String' }
              case opt.name
              when "rule_conditions_#{idx}"
                data[:value] = @conditions
                data[:type] = 'Array'
              when "rule_is_default_#{idx}"
                data[:value] = @is_default.to_s
              when "rule_default_style_css_#{idx}"
                data[:value] = @default_style_css || ''
              when "rule_default_style_icon_#{idx}"
                data[:value] = @default_style_icon || ''
              when "rule_min_value_#{idx}"
                data[:value] = @min_value.to_s if style_type == 'progress_bar'
              when "rule_max_value_#{idx}"
                data[:value] = @max_value.to_s if style_type == 'progress_bar'
              when "rule_show_label_#{idx}"
                data[:value] = @show_label.to_s if style_type == 'progress_bar'
              when "rule_default_css_class_#{idx}"
                data[:value] = @default_btn_css || 'btn-primary' if style_type == 'button'
              when "rule_default_icon_class_#{idx}"
                data[:value] = @default_btn_icon || '' if style_type == 'button'
              end
              data
            end

            unless concern.options.any? { |o| o.name == "rule_attr_id_#{idx}" }
              options_to_update << { name: "rule_attr_id_#{idx}", value: schema_attr.id.to_s, type: 'String' }
            end

            unless concern.options.any? { |o| o.name == "rule_is_default_#{idx}" }
              options_to_update << { name: "rule_is_default_#{idx}", value: @is_default, type: 'Boolean' }
            end

            unless concern.options.any? { |o| o.name == "rule_default_style_css_#{idx}" }
              options_to_update << { name: "rule_default_style_css_#{idx}", value: @default_style_css, type: 'String' }
            end

            unless concern.options.any? { |o| o.name == "rule_default_style_icon_#{idx}" }
              options_to_update << { name: "rule_default_style_icon_#{idx}", value: @default_style_icon, type: 'String' }
            end

            unless concern.options.any? { |o| o.name == "rule_conditions_#{idx}" }
              options_to_update << { name: "rule_conditions_#{idx}", value: @conditions, type: 'Array' }
            end

            if style_type == 'progress_bar'
              unless concern.options.any? { |o| o.name == "rule_min_value_#{idx}" }
                options_to_update << { name: "rule_min_value_#{idx}", value: @min_value.to_s, type: 'Integer' }
              end
              unless concern.options.any? { |o| o.name == "rule_max_value_#{idx}" }
                options_to_update << { name: "rule_max_value_#{idx}", value: @max_value.to_s, type: 'Integer' }
              end
              unless concern.options.any? { |o| o.name == "rule_show_label_#{idx}" }
                options_to_update << { name: "rule_show_label_#{idx}", value: @show_label.to_s, type: 'Boolean' }
              end
            end

            if style_type == 'button'
              unless concern.options.any? { |o| o.name == "rule_default_css_class_#{idx}" }
                options_to_update << { name: "rule_default_css_class_#{idx}", value: @default_btn_css || 'btn-primary', type: 'String' }
              end
              unless concern.options.any? { |o| o.name == "rule_default_icon_class_#{idx}" }
                options_to_update << { name: "rule_default_icon_class_#{idx}", value: @default_btn_icon || '', type: 'String' }
              end
            end

            concern.update(options_attributes: options_to_update).then do |response|
              mutate @saving = false
            end
          end

          def operator_options
            ::Crm::Datatable::StyleRuleEvaluator.operator_options
          end

          def progress_operator_options
            ::Crm::Datatable::StyleRuleEvaluator.progress_operator_options
          end
        end

      end
    end
  end
end