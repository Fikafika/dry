# backtick_javascript: true
require 'components/number_helper'

require 'uneek_formatting'

class Crm
  class Datatable
    module Column

      RENDER_TYPE_TEXT   = 'text'.freeze
      RENDER_TYPE_BUTTON = 'button'.freeze
      SUMMARY_TEXT_OPERATIONS = %w[count count_distinct].freeze

      def self.klass_from_method_name(klass, method_name)
        if klass.attributes[method_name]
          "#{self.name}::Attribute::#{klass.attributes[method_name]['type'].classify}".safe_constantize || Attribute::Base
        elsif method_name == 'type'
          Attribute::Type
        elsif klass.reflect_on_association(method_name)
          "#{self.name}::Association::#{klass.reflect_on_association(method_name).class.name.demodulize.gsub(/Reflection\z/, '')}".safe_constantize || Association::Base
        elsif klass.reflect_on_attachment(method_name)
          "#{self.name}::Attachment::#{klass.reflect_on_attachment(method_name).macro.classify}".safe_constantize || Attachment::Base # TODO check
        elsif klass.indexable_virtual_attributes[method_name]
          "#{self.name}::Attribute::#{klass.indexable_virtual_attributes.dig(method_name, 'type').classify}".safe_constantize || Attribute::Base
        end
      end

      class Base
        include UrlHelper

        attr_accessor :name
        attr_accessor :css_class
        attr_accessor :klass
        attr_accessor :method_name
        attr_accessor :depth
        attr_accessor :root_klass
        attr_accessor :path
        attr_accessor :human_name
        attr_accessor :panel_side
        attr_accessor :format
        attr_reader :format_method
        attr_reader :format_options
        attr_reader :cell_align_class

        def initialize(args = {})
          @name = args[:name]
          @css_class = args[:css_class]
          @klass = args[:klass]
          @method_name = args[:method_name]
          @root_klass = args[:root_klass]
          @depth = args[:depth]
          @format = args[:format]
          @render_sub_table = @name.include?('[]')
          @render_nested_without_sub_table = @name.include?('.') && !@render_sub_table
          @css_class ||= @name.gsub(/\./, '__').gsub(/\[|\]/, '')
          @editable = !['id', 'created_at', 'updated_at'].include?(@method_name)
          @path = @name.split('.').map{|r| r.gsub('[]', '')}
          @human_name = args[:human_name]
          @panel_side = args[:panel_side] || 'opposite'
          @format = args[:format]
          @format_options = args[:format_options] || {}
        end

        def render_cell_method
          return nil unless render_sub_table? || respond_to?(:render_cell_value) || has_render_styles?
          return @render_cell_method if @render_cell_method

          if render_sub_table?
            @render_cell_method = build_sub_table_renderer
          else
            @render_cell_method = build_cell_renderer
          end

          return @render_cell_method
        end

        def styled_cell_class_callback
          return nil if render_sub_table?

          compiled_css = compiled_styles[:css]
          default_css = compiled_styles[:css_default]
          return nil if compiled_css.empty? && !default_css
          evaluator = StyleRuleEvaluator.instance

          lambda do |td, cell_data, row_data, row, col_idx|
            css_classes = evaluator.compute_css_classes(compiled_css, row_data, cell_data, default: default_css)
            if css_classes.any?
              classes_str = css_classes.join(' ')
              `#{td}.className += ' ' + #{classes_str}`
            end
          end
        end

        def compiled_styles
          @compiled_styles ||= begin
            all = column_styles
            evaluator = StyleRuleEvaluator.instance
            btn = nil
            text_default = []
            text_cond = []
            visual_default = []
            visual_cond = []
            all.each do |s|
              if s[:render_type] == RENDER_TYPE_BUTTON
                btn = s
              elsif s[:render_type] == RENDER_TYPE_TEXT
                (s[:is_default] ? text_default : text_cond) << s
              else
                (s[:is_default] ? visual_default : visual_cond) << s
              end
            end
            {
              css: evaluator.compile_css_styles(text_cond, col: self),
              css_default: evaluator.compile_css_styles(text_default, col: self).first,
              visual: evaluator.compile_render_styles(visual_cond, col: self),
              visual_default: evaluator.compile_render_styles(visual_default, col: self).first,
              button: btn
            }
          end
        end

        def button_style
          compiled_styles[:button]
        end

        def has_render_styles?
          compiled_styles[:button] || compiled_styles[:visual].any? || compiled_styles[:visual_default]
        end

        def column_styles
          return [] unless klass&.respond_to?(:styles_for_attributes)
          klass.styles_for_attributes[method_name.to_s] || []
        end

        def path_prefix_for_style
          return nil if @path.length <= 1 || @render_sub_table
          @path[0..-2]
        end

        def sub_row_path
          @path[0..-2]
        end

        def record_type(data = nil, row = nil)
          tk = klass || (row && `#{row}['type']`.safe_constantize)
          tk&.name.to_s
        end

        def record_id(data, row)
          `#{row}['id']` || nil
        end

        private

        def build_cell_renderer
          base_renderer = base_cell_renderer
          btn_style = button_style
          if btn_style
            base_renderer = build_button_renderer(btn_style, base_renderer)
          elsif has_render_styles?
            base_renderer = build_styled_renderer(base_renderer)
          end
          if render_nested_without_sub_table?
            lambda do |data, type, row|
              next unless row
              r_row = `#{row}[#{@path[-2]}]` || nil
              base_renderer.call(data, type, r_row)
            end
          else
            base_renderer
          end
        end

        def build_styled_renderer(base_renderer)
          col = self
          evaluator = StyleRuleEvaluator.instance
          compiled = compiled_styles[:visual]
          default = compiled_styles[:visual_default]
          display_resolver = base_renderer || lambda { |data, _type, _row| data }
          lambda do |data, type, row|
            next data unless type == 'display'
            display_value = display_resolver.call(data, type, row)
            style = evaluator.determine_style(compiled, default, row, data)
            if style
              value_to_render = style[:use_raw_value] ? data : display_value
              col.render_style_html(style[:render_type], style[:render_options], value_to_render, display_value)
            else
              display_value
            end
          end
        end

        def build_button_renderer(button_style, base_renderer = nil)
          col = self
          options = button_style[:render_options] || {}
          style_rules  = options['style_rules'] || []
          default_css  = options['default_css_class'] || 'btn-primary'
          default_icon = options['default_icon_class'] || ''
          display_resolver = base_renderer || lambda { |data, _type, _row| data }
          lambda do |data, type, row|
            display = display_resolver.call(data, type, row)
            next display unless type == 'display'
            record_type = col.record_type(data, row)
            record_id = col.record_id(data, row)
            record_triggers = Crm::Datatable.triggers_for(record_type, record_id)
            next display unless record_triggers && record_triggers.any?
            html_parts = []
            record_triggers.each do |trigger|
              t_name   = trigger[:name].to_s
              t_action = trigger[:action].to_s
              t_icon   = trigger[:icon].to_s.presence
              t_icon   = "fa fa-#{t_icon}" if t_icon
              enabled  = trigger[:enabled] != false
              matched  = col.match_trigger_style(t_name, style_rules)
              css_class  = matched&.[]('css_class').presence || default_css
              icon_class = matched&.[]('icon_class').presence || t_icon || default_icon
              css_class  = "#{css_class} disabled" unless enabled
              html_parts << col.render_trigger_button_html(
                t_name, enabled ? t_action : '', css_class, icon_class, record_id, record_type
              )
            end
            %Q[<div class="d-flex justify-content-start">#{html_parts.join}</div>]
          end
        end

        def match_trigger_style(trigger_name, style_rules)
          name_lower = trigger_name.downcase
          style_rules.detect do |rule|
            pattern = (rule['value'] || '').to_s
            next false if pattern.empty?
            patterns = pattern.split('|').map { |p| p.strip.downcase }.reject(&:empty?)
            next false if patterns.empty?
            case rule['operator'] || '*='
            when '='
              patterns.any? { |p| name_lower == p }
            else
              patterns.any? { |p| name_lower.include?(p) }
            end
          end
        end

        def render_trigger_button_html(name, action, css_class, icon_class, record_id, record_type)
          icon_html = icon_class.present? ? %Q[<i class="#{icon_class} mr-1"></i>] : ''
          %Q[<a href="#action" class="btn btn-sm #{css_class} mr-1" data-action-click="#{action}" data-record-id="#{record_id}" data-record-type="#{record_type}" data-trigger-name="#{name}" data-column-name="#{self.name}">#{icon_html}#{name}</a>]
        end

        def build_sub_table_renderer
          cell_renderer = build_sub_cell_renderer
          lambda do |data, type, row|
            next data unless data.is_a?(Array)
            result = '<table class="table sub_table">'
            result += if cell_renderer
              render_sub_cells(data) { |d, nums| cell_renderer.call(d, nums, type, row) }
            else
              render_sub_cells(data)
            end
            result += '</table>'
            result
          end
        end

        def build_sub_cell_renderer
          sub_cell_method = base_cell_renderer
          col = self
          has_styles = column_styles.any?
          return nil if !sub_cell_method && !has_styles
          unless has_styles
            return lambda do |d, nums, type, row|
              sub_row = col.send(:resolve_sub_row, row, nums)
              [sub_cell_method.call(d, type, sub_row), nil]
            end
          end
          btn_style = button_style
          if btn_style
            return build_sub_button_renderer(btn_style, sub_cell_method)
          end

          evaluator = StyleRuleEvaluator.instance
          compiled_css     = compiled_styles[:css]
          css_default      = compiled_styles[:css_default]
          compiled_render  = compiled_styles[:visual]
          render_default   = compiled_styles[:visual_default]
          has_css    = compiled_css.any? || css_default
          has_render = compiled_render.any? || render_default
          display_resolver = if sub_cell_method
            lambda { |d, type, sub_row| sub_cell_method.call(d, type, sub_row) }
          else
            lambda { |d, type, sub_row| d }
          end
          lambda do |d, nums, type, row|
            sub_row = col.send(:resolve_sub_row, row, nums)
            display = display_resolver.call(d, type, sub_row)

            if has_render && type == 'display'
              style = evaluator.determine_style(compiled_render, render_default, sub_row, d)
              if style
                value_to_render = style[:use_raw_value] ? d : display
                display = col.render_style_html(style[:render_type], style[:render_options], value_to_render, display)
              end
            end

            extra_css = nil
            if has_css
              css_classes = evaluator.compute_css_classes(compiled_css, sub_row, d, default: css_default)
              extra_css = " #{css_classes.join(' ')}" if css_classes.any?
            end

            [display, extra_css]
          end
        end

        def build_sub_button_renderer(button_style, sub_cell_method)
          col = self
          options = button_style[:render_options] || {}
          style_rules  = options['style_rules'] || []
          default_css  = options['default_css_class'] || 'btn-primary'
          default_icon = options['default_icon_class'] || ''
          display_resolver = if sub_cell_method
            lambda { |d, type, sub_row| sub_cell_method.call(d, type, sub_row) }
          else
            lambda { |d, type, sub_row| d }
          end
          lambda do |d, nums, type, row|
            sub_row = col.send(:resolve_sub_row, row, nums)
            display = display_resolver.call(d, type, sub_row)
            next [display, nil] unless type == 'display'
            record_type = col.record_type(d, sub_row)
            record_id = `sub_row['id']` || nil
            record_triggers = Crm::Datatable.triggers_for(record_type, record_id)
            next [display, nil] unless record_triggers && record_triggers.any?
            html_parts = []
            record_triggers.each do |trigger|
              t_name   = trigger[:name].to_s
              t_action = trigger[:action].to_s
              t_icon   = trigger[:icon].to_s.presence
              t_icon   = "fa fa-#{t_icon}" if t_icon
              enabled  = trigger[:enabled] != false
              matched  = col.match_trigger_style(t_name, style_rules)
              css_class  = matched&.[]('css_class').presence || default_css
              icon_class = matched&.[]('icon_class').presence || t_icon || default_icon
              css_class  = "#{css_class} disabled" unless enabled
              html_parts << col.render_trigger_button_html(
                t_name, enabled ? t_action : '', css_class, icon_class, record_id, record_type
              )
            end
            [%Q[<div class="d-flex justify-content-start">#{html_parts.join}</div>], nil]
          end
        end

        def resolve_sub_row(row, nums)
          sub_row = row
          nums_i = 0

          sub_row_path.each do |a|
            sub_row = `sub_row[#{a}]`
            return nil unless sub_row
            if `sub_row.$$is_array`
              sub_row = `sub_row[#{nums[nums_i]}]`
              nums_i += 1
            end
          end

          sub_row
        end

        def base_cell_renderer
          if render_link?
            col = self
            lambda do |data, type, row|
              col.render_link(data, `#{row}.id`)
            end
          elsif render_link_open_panel?
            col = self
            lambda do |data, type, row|
              col.render_link_open_panel(klass, `#{row}.id`, data)
            end
          elsif respond_to?(:render_cell_value)
            col = self
            lambda do |data, type, row|
              col.render_cell_value(data, row)
            end
          end
        end

        def render_style_html(render_type, options, value, display_value = nil)
          options ||= {}
          case render_type
          when 'progress_bar'
            render_progress_bar_html(value, options, display_value)
          when 'badge'
            render_badge_html(value, options)
          when 'icon'
            render_icon_html(value, options)
          else
            value.to_s
          end
        end

        def render_progress_bar_html(value, options, display_value = nil)
          numeric_value = clean_value(value).to_f
          min_val = (options['min_value'] || 0).to_f
          max_val = (options['max_value'] || 100).to_f
          range = max_val - min_val
          percentage = range > 0 ? (((numeric_value - min_val) / range) * 100) : 0
          percentage = [[percentage, 0].max, 100].min
          css_class = options['css_class'] || 'bg-primary'
          show_label = options['show_label'].to_s == 'true'
          label = show_label ? clean_value(display_value.to_s.presence || value) : ''
          wrapper_class = options['wrapper_class'] || 'progress'
          %Q[<div class="#{wrapper_class}" style="height: 20px;"><div class="progress-bar #{css_class}" role="progressbar" style="width: #{percentage}%;" aria-valuenow="#{numeric_value}" aria-valuemin="#{min_val}" aria-valuemax="#{max_val}">#{label}</div></div>]
        end

        def render_badge_html(value, options)
          icon_class = options['icon_class'] || options[:icon_class]
          css_class = options['css_class'] || options[:css_class] || ''
          content = ''
          if icon_class.present?
            content += %Q[<i class="#{icon_class}"></i>]
          end
          content += clean_value(value)
          pill = (options['pill'] || options[:pill]) ? 'badge-pill' : ''
          %Q[<span class="badge #{css_class} #{pill}">#{content}</span>]
        end

        def render_icon_html(value, options)
          icon_class = options['icon_class'] || options[:icon_class] || 'fas fa-circle'
          css_class = options['css_class'] || options[:css_class] || ''
          show_text = options['show_text'] != false && options[:show_text] != false
          text_part = show_text ? %Q[<span class="ml-1">#{clean_value(value)}</span>] : ''
          %Q[<span class="#{css_class}"><i class="#{icon_class}"></i>#{text_part}</span>]
        end

        def clean_value(value)
          value.to_s.gsub(/<\/?(?!a\b)[^>]*>/i, '')
        end

        def render_sub_cells(data, nums = [], &block)
          result = ''
          data.each_with_index do |d, i|
            nums_ = nums + [i]
            if `d.$$is_array`
              result += render_sub_cells(d, nums_, &block)
            else
              if block_given?
                content, extra_css = yield(d, nums_)
              else
                content = d
                extra_css = nil
              end
              td_class = "#{'cell-editable' if editable?}#{extra_css}"
              result += %Q[<tr><td class="#{td_class}" data-nums="#{nums_.join(',')}">#{content}</td></tr>]
            end
          end
          result
        end

        def render_sub_table?
          @render_sub_table
        end

        def render_nested_without_sub_table?
          @render_nested_without_sub_table
        end

        def summary_operations
          SUMMARY_TEXT_OPERATIONS
        end

        def default_summary_operation
          'count'
        end

        def filters_menu
          [
            "contains",
            "not_contains",
            "equal",
            "not_equal",
            "empty",
            "not_empty",
            "starts_with",
            "ends_with",
            "length_equal_to"
          ]
        end

        def default_operator
          'contains'
        end

        def editable?
          @editable
        end

        def convert_value_to_filter_input_value(value)
          value
        end

        def convert_value_from_filter_input_value(value)
          value
        end

        def human_path
          return @human_path if @human_path
          @human_path = human_path_without_cache
          return @human_path
        end

        def human_path_without_cache
          result = []
          k = root_klass
          self.name.gsub(/\]|\[/, '').split('.').each do |method_name|
            result << k.human_attribute_name(method_name)
            k = k.reflect_on_association(method_name)&.klass
            break unless k
          end
          return result
        end

        def render_link_open_panel(klass, id, text)
          %Q[<a href="#{url_for(action: :edit, klass: klass, id: id)}" data-open-panel="#{panel_side}">#{text}</a>]
        end

        def render_link_open_panel?
          self.method_name == 'id' || self.method_name == klass.name_attribute
        end

        def render_link(value, record_id)
          value = replace_para(value)

          title = value
          protocols = klass.protocols_for_attributes[method_name.to_sym]
          if protocols.present?
            prefered_protocol = protocols.first
            protocol_formated = 'http' == prefered_protocol ? '' : "#{prefered_protocol}:"

            inner_html = %Q[<a href="#{protocol_formated}#{value}" x-record-id=#{record_id} x-record-type=#{klass.name}>#{value}</a>]
          else
            inner_html = value
          end
          %Q[<span class="text-overflow-dynamic-container"><span class="text-overflow-dynamic-ellipsis" title="#{title}">#{inner_html}</span></span>]
        end

        def replace_para(value)
          value
        end

        def render_link?
          klass.respond_to?(:protocols_for_attributes) && klass.protocols_for_attributes[method_name.to_sym].present?
        end

        def form_id_for(action)
        end

      end

      module Attribute

        module ReplacePara
          def replace_para(value)
            # workaround a weird browser behavior: &para character entity is replaced even without ;
            # see https://html.spec.whatwg.org/multipage/named-characters.html
            # it fixes url that contains &params=

            value = `#{value}.replace(/(&para[^;])/g, function (m) { return m.replace('&', '&amp;'); })` if value
          end
        end

        class Base < ::Crm::Datatable::Column::Base

        end

        class String < Base
          include ReplacePara

          def render_cell_value(value, row)
            %Q[<span class="text-overflow-dynamic-container"><span class="text-overflow-dynamic-ellipsis" title="#{value}">#{value}</span></span>]
          end

        end

        class Text < Base
          include ReplacePara
        end

        class TranslatableString < String
        end

        class TranslatableText < Base
          include ReplacePara
        end

        class Number < Base
          include UneekFormatting::Dynamic::AttributeFormatter

          SUMMARY_NUMERIC_OPERATIONS = %w[count sum avg min max count_distinct].freeze

          def initialize(args = {})
            super
            if @format
              @format_method, @format_options = format_method_for_key(@format, @format_options)
            else
              @format_method, @format_options = format_method_for(klass, method_name)
            end
            @cell_align_class = compute_cell_align_class
          end

          def render_cell_value(value, row)
            return nil unless value
            return `#{value}.toLocaleString()` unless format_method
            send(format_method, value, format_options)
          end

          def compute_cell_align_class
            'text-right'
          end

          def filters_menu
            [
              "contains",
              "not_contains",
              "equal",
              "not_equal",
              "greater_equal",
              "lesser_equal",
              "empty",
              "not_empty",
              "starts_with",
              "ends_with",
              "length_equal_to"
            ]
          end

          def default_operator
            'equal'
          end

          def summary_operations
            SUMMARY_NUMERIC_OPERATIONS
          end

        end

        class Integer < Number
          def convert_value_from_filter_input_value(value)
            Integer(value) rescue nil
          end
        end

        class Float < Number

          def convert_value_from_filter_input_value(value)
            Float(value) rescue nil
          end

        end

        class Uuid < Base

          def render_cell_value(value, row)
            %Q[<span class="text-overflow-dynamic-container"><span class="text-overflow-dynamic-ellipsis" title="#{value}">#{value}</span></span>]
          end

          def filters_menu
            [
              "contains",
              "not_contains",
              "equal",
              "not_equal",
              "greater_equal",
              "lesser_equal",
              "empty",
              "not_empty",
              "starts_with",
              "ends_with",
            ]
          end

        end

        class Enum < Base

          def render_cell_value(value, row)
            mapping[value] || value
          end

          def mapping
            @mapping ||= (self.klass.attributes.dig(method_name, :mapping_invert, I18n.locale) || {})
          end

          def filters_menu
            [
              "equal",
              "not_equal",
              "empty",
              "not_empty",
            ]
          end

          def default_operator
            'equal'
          end

          def convert_value_to_filter_input_value(value)
            mapping[value]
          end

          def convert_value_from_filter_input_value(value)
            mapping.each do |k, v|
              if v.downcase =~ /#{value}/
                return k
              end
            end
          end
        end

        class Boolean < Enum

          def mapping
            @mapping ||= {
              true => I18n.t('shared._yes').capitalize,
              false => I18n.t('shared._no').capitalize,
            }
          end

          def convert_value_from_filter_input_value(value)
            mapping_invert[value.to_s.downcase]
          end

          def mapping_invert
            @mapping_invert ||= {
              I18n.t('shared._yes').downcase => true,
              I18n.t('shared._no').downcase => false,
              I18n.t('shared._yes').downcase[0].to_s => true,
              I18n.t('shared._no').downcase[0].to_s => false,
            }
          end

        end

        class Date < Base
          include UneekFormatting::Dynamic::AttributeFormatter

          def initialize(args = {})
            super
            if @format
              @format_method, @format_options = format_method_for_key(@format, @format_options, attribute_type_name)
            else
              @format_method, @format_options = format_method_for(klass, method_name)
            end
          end

          def attribute_type_name
            'Date'
          end

          def fallback_display_format
            I18n.t('format.date')
          end

          def default_operator
            'equal'
          end

          def render_cell_value(value, row)
            return unless value.present?
            return send(@format_method, value, @format_options) if @format_method
            `moment(#{value}).format(#{fallback_display_format})`
          end

          def convert_value_from_filter_input_value(value)
            value ? `moment(#{value}).format('YYYY-MM-DD')` : nil
          end

          def convert_value_to_filter_input_value(value)
            return value
          end

          def filters_menu
            [
              "equal",
              "not_equal",
              "today",
              "this_week",
              "this_month",
              "this_year",
              "before",
              "after",
              "ago",
              "since",
              "until",
              "past",
              "future",
              "empty",
              "not_empty",
            ]
          end

        end

        class DateTime < Date

          def attribute_type_name
            'DateTime'
          end

          def fallback_display_format
            I18n.t('format.date_time')
          end

          def default_operator
            'date_equal'
          end

          def convert_value_from_filter_input_value(value)
            value ? `moment(#{value}).format('YYYY-MM-DD')` : nil
          end

          def convert_value_to_filter_input_value(value)
            return value
          end

          def filters_menu
            [
              "date_equal",
              "date_not_equal",
              "equal",
              "not_equal",
              "today",
              "this_week",
              "this_month",
              "this_year",
              "before",
              "after",
              "ago",
              "since",
              "until",
              'past',
              'future',
              'previous_days',
              'following_days',
              "empty",
              "not_empty",
            ]
          end

        end

        class TimeOfDay < Base

          def default_operator
            'equal'
          end

          def convert_value_from_filter_input_value(value)
            value ? `moment(#{value}).format(#{I18n.t('format.time_of_day')})` : nil
          end

          def filters_menu
            [
              "equal",
              "not_equal",
              "empty",
              "not_empty",
            ]
          end
        end

        class Type < Base

          def default_operator
            'equal'
          end

          def filters_menu
            [
              "equal",
              "not_equal",
              "empty",
              "not_empty",
            ]
          end

          def render_cell_value(value, row)
            return unless value
            value.safe_constantize&.model_name&.human
          end

          def convert_value_to_filter_input_value(value)
            value.safe_constantize&.model_name&.human
          end

          def convert_value_from_filter_input_value(value)
            ([self.klass] + self.klass.descendants).detect{|k| k.model_name.human.to_s.downcase.include?(value.downcase)}
          end

        end
      end

      module Association

        class Base < ::Crm::Datatable::Column::Base

          def default_operator
            'contains_id'
          end

          def filters_menu
            [
              "contains_id",
              "not_contains_id",
              "contains_name",
              "not_contains_name",
              "empty",
              "not_empty",
            ]
          end

          def render_cell_value(value, row)
            return unless value
            klass = target_klass || (value && `#{value}['type']`.safe_constantize)
            return unless klass

            text = `#{value}[#{klass.name_attribute}]` || `value['polymorphic_name']` || ''
            text = render_link_open_panel(klass, `value['id']`, text)

            attachment = `#{value}[#{klass.photo_attachment}]`
            signed_id = `#{attachment}.attachment && #{attachment}.attachment.signed_id` if attachment

            fallback_icon = klass.try(:icon)

            if signed_id
              photo = %Q[
                <img src="#{ENV['APP_PATH_PREFIX']}/api/files/representations/#{signed_id}/icon/icon.png" class="cell-item-icon mr-1" onerror="$(this).addClass('d-none'); $(this).next().removeClass('d-none')"/>
              ]
            end
            result = %Q[
              <span>
                #{photo}
                <span class="cell-item-icon #{signed_id ? 'd-none' : nil} mr-1">
                  <i class="fas fa-#{fallback_icon} fa-inverse"></i>
                </span>
                #{text}
              </span>
            ].gsub(/\>\n\s*/, '>') # prevent additional spaces
            return result

          end

          def target_klass
            klass.reflect_on_association(method_name).klass
          end

          def record_type(data = nil, row = nil)
            tk = target_klass || (data && `#{data}['type']`.safe_constantize)
            tk&.name.to_s
          end

          def record_id(data, row)
            `#{data}['id']` || nil
          end

          def column_styles
            styles = super
            return styles if styles.any?
            return [] unless target_klass&.respond_to?(:styles_for_attributes)
            target = target_klass
            target.styles_for_attributes[target.name_attribute.to_s] || []
          end

          def path_prefix_for_style
            return nil if @render_sub_table
            @path
          end

          def sub_row_path
            @path
          end

          def form_id_for(action)
            f = Dynamic::Form.where(
              schema_id: klass.parent.name.demodulize,
              klass_id: klass.model_name.route_key,
              association_name: method_name,
            ).with_action(action).first
            return unless f
            f.__promise__.then do
              yield(f.id) if f.loaded?
            end
          end

        end

        class HasMany < Base; end
        class BelongsTo < Base; end

      end

      module Attachment

        class Base < ::Crm::Datatable::Column::Base

          def self.compute_image_extensions_reg(exts)
            return Regexp.new(exts.map{|e| ".#{e}$"}.join('|'), 'i')
          end

          IMAGE_EXTENSIONS_REG = compute_image_extensions_reg(
            [
              'png',
              'jpeg',
              'jpg',
              'jiff',
              'gif',
              'bmp',
            ]
          )

          def render_attachment(signed_id, filename)
            download_path = "#{ENV['APP_PATH_PREFIX']}/api/files/blobs/#{signed_id}/#{filename}" # is used in right clic menu

            if filename =~ IMAGE_EXTENSIONS_REG
              src = "#{ENV['APP_PATH_PREFIX']}/api/files/representations/#{signed_id}/attachment-icon/icon.png"
              preview = "#{ENV['APP_PATH_PREFIX']}/api/files/representations/#{signed_id}/preview/preview.png"
              img = %Q[<img src="#{src}" class="cell-img" onerror="$(this).addClass('d-none'); $(this).next().removeClass('d-none')" data-toggle="tooltip" title="<img style='background-color: white' src='#{preview}'/>"/>]
              result = %Q[
                <span class="text-overflow-dynamic-container" title="#{filename}" data-download-path="#{download_path}">
                  #{img}
                  <span class="d-none text-overflow-dynamic-ellipsis">#{filename}</span>
                </span>
              ].gsub(/\>\n\s*/, '>')
              return result
            else
              return %Q[<span class="text-overflow-dynamic-container" title="#{filename}" data-download-path="#{download_path}"><span class="text-overflow-dynamic-ellipsis">#{filename}</span></span>]
            end
          end

        end

        class HasOneAttached < Base

          def render_cell_value(value, row)
            return unless value && `#{value}.attachment`

            signed_id = `#{value}.attachment.signed_id`
            filename = `#{value}.attachment.filename`
            return render_attachment(signed_id, filename)
          end

        end

        class HasManyAttached < Base

          def render_cell_value(value, row)
            return unless value && `#{value}.attachments`

            r = Array(`#{value}.attachments`).map do |a|
              signed_id = `#{a}.signed_id`
              filename = `#{a}.filename`
              "<div>" + render_attachment(signed_id, filename) + "</div>"
            end
            return unless r.any?
            return r.join
          end

        end

      end
    end
  end
end
