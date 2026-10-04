# backtick_javascript: true

module Dynamic
  module Datatable
    module Style

      module CellColor; end
      module RowColor; end
      module Badge; end
      module Icon; end
      module ProgressBar; end
      module Button; end

      module Feature
        def self.load_constants(schema)
          feature = schema.features.detect { |f| f.name == 'Dynamic::Datatable::Style::Feature' }
          return unless feature

          schema.klasses.each do |schema_klass|
            klass_const = schema_klass.const
            next unless klass_const
            klass_const.define_singleton_method(:styles_for_attributes) do
              @_styles_for_attributes ||= Feature.inherited_cell_styles(schema_klass, feature, schema)
            end
            klass_const.define_singleton_method(:row_styles) do
              @_row_styles ||= Feature.inherited_row_styles(schema_klass, feature, schema)
            end
          end
        end

        def self.inherited_cell_styles(schema_klass, feature, schema)
          result = schema_klass.superklass ? inherited_cell_styles(schema_klass.superklass, feature, schema) : {}
          return result.merge(StyleBuilder.build_cell_styles(klass_concerns(schema_klass, feature), schema))
        end

        def self.inherited_row_styles(schema_klass, feature, schema)
          own = StyleBuilder.build_row_styles(klass_concerns(schema_klass, feature), schema)
          return own if own.any?
          return schema_klass.superklass ? inherited_row_styles(schema_klass.superklass, feature, schema) : []
        end

        def self.klass_concerns(schema_klass, feature)
          feature.concerns.select { |c| c.klass_id == schema_klass.id }
        end
      end

      class StyleBuilder
        class << self
          def build_cell_styles(concerns, schema)
            styles_by_attr = {}
            concerns.each do |concern|
              next unless concern
              options = options_to_hash(concern.options)
              case concern.name
              when 'CellColor'    then merge_styles(styles_by_attr, parse_cell_color(options, schema))
              when 'Badge'        then merge_styles(styles_by_attr, parse_badge(options, schema))
              when 'Icon'         then merge_styles(styles_by_attr, parse_icon(options, schema))
              when 'ProgressBar'  then merge_styles(styles_by_attr, parse_progress_bar(options, schema))
              when 'Button'       then merge_styles(styles_by_attr, parse_button(options, schema))
              end
            end
            styles_by_attr
          end

          def build_row_styles(concerns, schema)
            row_styles = []
            concerns.each do |concern|
              next unless concern&.name == 'RowColor'
              options = options_to_hash(concern.options)
              row_styles.concat(parse_row_color(options, schema))
            end
            row_styles
          end

          def options_to_hash(options_collection)
            return {} unless options_collection
            options_collection.to_h { |opt| [opt.name, opt.value] }
          end

          def merge_styles(target, source)
            source.each do |attr_name, styles|
              target[attr_name] ||= []
              target[attr_name].concat(styles)
            end
          end

          def resolve_condition_attr(cond, default_attr_name, schema)
            cond_attr_id = cond['condition_attr_id'].presence
            return default_attr_name unless cond_attr_id
            schema.attr_or_assoc_or_attach_by_id[cond_attr_id]&.name || default_attr_name
          end

          def build_rule(attr_name, cond)
            {
              attribute_name: attr_name,
              operator: cond['operator'],
              value: cond['value'],
              value_type: detect_value_type(cond['value']),
              logical_operator: 'and',
            }
          end

          def detect_value_type(value)
            return 'string' if value.nil?
            str = value.to_s
            return 'integer' if str =~ /\A-?\d+\z/ && str !~ /\A0\d/
            return 'float'   if str =~ /\A-?\d+\.\d+\z/
            return 'boolean' if %w[true false].include?(str.downcase)
            'string'
          end

          def each_rule(options, schema)
            options.keys.map { |k| k[/rule_attr_id_(\d+)/, 1] }.compact.uniq.each do |idx|
              attr_id = options["rule_attr_id_#{idx}"]
              attr_name = schema.attr_or_assoc_or_attach_by_id[attr_id]&.name
              next if attr_name.blank?
              conditions = options["rule_conditions_#{idx}"] || []
              default_info = {
                is_default: options["rule_is_default_#{idx}"].to_s == 'true',
                css: options["rule_default_style_css_#{idx}"],
                icon: options["rule_default_style_icon_#{idx}"],
              }

              yield(idx, attr_name, conditions, default_info)
            end
          end

          def parse_cell_color(options, schema)
            styles_by_attr = {}
            each_rule(options, schema) do |_idx, attr_name, conditions, default_info|
              next if conditions.empty? && !default_info[:is_default]
              styles_by_attr[attr_name] ||= []
              if default_info[:is_default] && default_info[:css].present?
                styles_by_attr[attr_name] << {
                  type: 'CellColor',
                  render_type: 'text',
                  render_options: { 'css_class' => default_info[:css] },
                  rules: [],
                  is_default: true,
                }
              end
              conditions.each do |cond|
                styles_by_attr[attr_name] << {
                  type: 'CellColor',
                  render_type: 'text',
                  render_options: { 'css_class' => cond['css_class'] },
                  rules: [build_rule(resolve_condition_attr(cond, attr_name, schema), cond)],
                }
              end
            end
            styles_by_attr
          end

          def parse_row_color(options, schema)
            row_styles = []
            each_rule(options, schema) do |_idx, attr_name, conditions, _default_info|
              conditions.each do |cond|
                row_styles << {
                  type: 'RowColor',
                  render_type: 'text',
                  render_options: { 'css_class' => cond['css_class'] },
                  rules: [build_rule(resolve_condition_attr(cond, attr_name, schema), cond)],
                }
              end
            end
            row_styles
          end

          def parse_badge(options, schema)
            styles_by_attr = {}
            each_rule(options, schema) do |idx, attr_name, conditions, default_info|
              next if conditions.empty? && !default_info[:is_default]
              pill = options["rule_pill_#{idx}"].to_s == 'true'
              styles_by_attr[attr_name] ||= []
              if default_info[:is_default] && default_info[:css].present?
                styles_by_attr[attr_name] << {
                  type: 'Badge',
                  render_type: 'badge',
                  render_options: { 'css_class' => default_info[:css], 'pill' => pill },
                  rules: [],
                  is_default: true,
                }
              end

              conditions.each do |cond|
                styles_by_attr[attr_name] << {
                  type: 'Badge',
                  render_type: 'badge',
                  render_options: { 'css_class' => cond['css_class'], 'pill' => pill },
                  rules: [build_rule(resolve_condition_attr(cond, attr_name, schema), cond)],
                }
              end
            end
            styles_by_attr
          end

          def parse_icon(options, schema)
            styles_by_attr = {}
            each_rule(options, schema) do |idx, attr_name, conditions, default_info|
              next if conditions.empty? && !default_info[:is_default]
              show_text = options["rule_show_text_#{idx}"].to_s != 'false'
              styles_by_attr[attr_name] ||= []
              if default_info[:is_default]
                default_css = default_info[:css] || ''
                default_icon = default_info[:icon] || ''
                styles_by_attr[attr_name] << {
                  type: 'Icon',
                  render_type: 'icon',
                  render_options: {
                    'css_class' => default_css,
                    'icon_class' => default_icon,
                    'show_text' => show_text,
                  },
                  rules: [],
                  is_default: true,
                }
              end

              conditions.each do |cond|
                styles_by_attr[attr_name] << {
                  type: 'Icon',
                  render_type: 'icon',
                  render_options: {
                    'css_class' => cond['css_class'],
                    'icon_class' => cond['icon_class'],
                    'show_text' => show_text,
                  },
                  rules: [build_rule(resolve_condition_attr(cond, attr_name, schema), cond)],
                }
              end
            end
            styles_by_attr
          end

          def parse_progress_bar(options, schema)
            styles_by_attr = {}
            each_rule(options, schema) do |idx, attr_name, conditions, _default_info|
              min_val = (options["rule_min_value_#{idx}"] || 0).to_i
              max_val = (options["rule_max_value_#{idx}"] || 100).to_i
              show_lbl = options["rule_show_label_#{idx}"].nil? ? true : (options["rule_show_label_#{idx}"].to_s == 'true')
              render_opts = {
                'min_value' => min_val,
                'max_value' => max_val,
                'show_label' => show_lbl,
                'wrapper_class' => 'progress',
                'label_format' => '{value}%',
              }
              styles_by_attr[attr_name] ||= []
              conditions.each do |cond|
                styles_by_attr[attr_name] << {
                  type: 'ProgressBar',
                  render_type: 'progress_bar',
                  render_options: render_opts.merge('css_class' => cond['css_class']),
                  rules: [build_rule(resolve_condition_attr(cond, attr_name, schema), cond)],
                }
              end
              styles_by_attr[attr_name] << {
                type: 'ProgressBar',
                render_type: 'progress_bar',
                render_options: render_opts.merge('css_class' => 'bg-primary'),
                rules: [],
              }
            end
            styles_by_attr
          end

          def parse_button(options, schema)
            styles_by_attr = {}
            each_rule(options, schema) do |idx, attr_name, conditions, _default_info|
              default_css  = options["rule_default_css_class_#{idx}"] || 'btn-primary'
              default_icon = options["rule_default_icon_class_#{idx}"] || ''
              style_rules = conditions.map do |cond|
                {
                  'operator'   => cond['operator'] || '*=',
                  'value'    => (cond['value'] || '').to_s,
                  'css_class'  => cond['css_class'] || 'btn-primary',
                  'icon_class' => cond['icon_class'] || '',
                }
              end
              styles_by_attr[attr_name] ||= []
              styles_by_attr[attr_name] << {
                type: 'Button',
                render_type: 'button',
                render_options: {
                  'style_rules'        => style_rules,
                  'default_css_class'  => default_css,
                  'default_icon_class' => default_icon,
                },
                rules: [],
              }
            end
            styles_by_attr
          end
        end
      end

    end
  end
end