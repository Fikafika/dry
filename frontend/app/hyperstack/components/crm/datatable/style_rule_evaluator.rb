# backtick_javascript: true

class Crm
  class Datatable
    class StyleRuleEvaluator
      include Singleton

      OPERATORS = [
        { value: '=',   i18n_key: 'settings.attributes.styles.operators.equal' },
        { value: '!=',  i18n_key: 'settings.attributes.styles.operators.not_equal' },
        { value: '>',   i18n_key: 'settings.attributes.styles.operators.greater_than' },
        { value: '>=',  i18n_key: 'settings.attributes.styles.operators.greater_than_or_equal' },
        { value: '<',   i18n_key: 'settings.attributes.styles.operators.less_than' },
        { value: '<=',  i18n_key: 'settings.attributes.styles.operators.less_than_or_equal' },
        { value: '><',  i18n_key: 'settings.attributes.styles.operators.between' },
        { value: '*=',  i18n_key: 'settings.attributes.styles.operators.contains' },
        { value: '!*=', i18n_key: 'settings.attributes.styles.operators.not_contains' },
        { value: '^=',  i18n_key: 'settings.attributes.styles.operators.starts_with' },
        { value: '$=',  i18n_key: 'settings.attributes.styles.operators.ends_with' },
        { value: '=~',  i18n_key: 'settings.attributes.styles.operators.matches_regex' },
        { value: '∅',   i18n_key: 'settings.attributes.styles.operators.is_blank' },
        { value: '!∅',  i18n_key: 'settings.attributes.styles.operators.is_not_blank' },
        { value: '[]',  i18n_key: 'settings.attributes.styles.operators.in_list' },
        { value: '![]', i18n_key: 'settings.attributes.styles.operators.not_in_list' },
      ].freeze

      def self.operator_options
        OPERATORS
      end

      def self.progress_operator_options
        OPERATORS.select { |op| %w[>= > <= < =].include?(op[:value]) }
      end

      def determine_style(conditionals, default, row_data, cell_data)
        style = conditionals.detect { |s| evaluate_rules(s[:rules], row_data, cell_data) }
        return style if style
        return nil if value_blank?(cell_data)
        return default
      end

      def compute_css_classes(conditionals, row_data, cell_data = nil, default: nil)
        classes = conditionals.each_with_object([]) do |style, arr|
          arr << style[:css_class] if evaluate_rules(style[:rules], row_data, cell_data)
        end
        return classes if classes.any?
        return [] unless default && !value_blank?(cell_data)
        return [default[:css_class]]
      end

      def compile_rules(rules, path_prefix: nil)
        return [] if rules.nil? || rules.empty?
        rules.map do |rule|
          attr_name = rule[:attribute_name]
          path = if path_prefix && attr_name.present?
            path_prefix + [attr_name.to_s]
          elsif attr_name.present?
            [attr_name.to_s]
          end
          {
            attribute_name: attr_name,
            path: path,
            operator: rule[:operator] || rule['operator'],
            value: rule[:value] || rule['value'],
            value_type: rule[:value_type] || rule['value_type'] || 'string',
            second_value: rule[:second_value] || rule['second_value'],
            logical_operator: rule[:logical_operator] || rule['logical_operator']
          }
        end
      end

      def evaluate_rules(rules, row_data, cell_data)
        return true if rules.empty?
        result = true
        rules.each_with_index do |rule, index|
          rule_result = evaluate_single_rule(rule, row_data, cell_data)
          if index == 0
            result = rule_result
          elsif rule[:logical_operator] == 'or'
            result = result || rule_result
          else
            result = result && rule_result
          end
        end
        result
      end

      def evaluate_single_rule(rule, row_data, cell_data)
        actual_value = if rule[:path]
          get_nested_value(row_data, rule[:path])
        else
          cell_data
        end
        expected = cast_value(rule[:value], rule[:value_type])
        expected_second = rule[:second_value].present? ? cast_value(rule[:second_value], rule[:value_type]) : nil
        compare_values(actual_value, expected, expected_second, rule[:operator])
      end

      def get_nested_value(data, path)
        return nil unless data
        return nil if `#{data} === undefined || #{data} === null`
        current = data
        path.each do |part|
          return nil if `#{current} === undefined || #{current} === null`
          is_js_object = `typeof #{current} === 'object' && #{current} !== null && !#{current}.$$class`
          if is_js_object
            current = `#{current}[#{part}]`
          elsif current.is_a?(Hash)
            current = current[part]
          elsif current.respond_to?(part)
            current = current.send(part)
          else
            return nil
          end
          return nil if `#{current} === undefined || #{current} === null`
        end

        current
      end

      def cast_value(val, type)
        return nil if val.nil?
        case type
        when 'integer'
          val.to_i
        when 'float'
          val.to_f
        when 'boolean'
          val == true || val == 'true' || val == '1'
        else
          val.to_s
        end
      end

      def compare_values(actual, expected, expected_second, operator)
        case operator
        when '='
          actual.to_s == expected.to_s
        when '!='
          actual.to_s != expected.to_s
        when '>'
          to_number(actual) > to_number(expected)
        when '<'
          to_number(actual) < to_number(expected)
        when '>='
          to_number(actual) >= to_number(expected)
        when '<='
          to_number(actual) <= to_number(expected)
        when '><'
          num = to_number(actual)
          num >= to_number(expected) && num <= to_number(expected_second)
        when '*='
          actual.to_s.downcase.include?(expected.to_s.downcase)
        when '!*='
          !actual.to_s.downcase.include?(expected.to_s.downcase)
        when '^='
          actual.to_s.downcase.start_with?(expected.to_s.downcase)
        when '$='
          actual.to_s.downcase.end_with?(expected.to_s.downcase)
        when '=~'
          !!(actual.to_s =~ Regexp.new(expected.to_s))
        when '∅'
          value_blank?(actual)
        when '!∅'
          !value_blank?(actual)
        when '[]'
          list = expected.to_s.split(',').map { |v| v.strip.downcase }
          list.include?(actual.to_s.downcase)
        when '![]'
          list = expected.to_s.split(',').map { |v| v.strip.downcase }
          !list.include?(actual.to_s.downcase)
        else
          false
        end
      end

      def compile_css_styles(styles, col: nil)
        path_prefix = col&.path_prefix_for_style
        styles.filter_map do |style|
          css_class = style.dig(:render_options, 'css_class') || style.dig(:render_options, :css_class)
          next if css_class.blank?
          {
            css_class: css_class,
            rules: compile_rules(style[:rules], path_prefix: path_prefix)
          }
        end
      end

      def compile_render_styles(styles, col: nil)
        path_prefix = col&.path_prefix_for_style
        styles.map do |style|
          {
            type: style[:type],
            render_type: style[:render_type],
            render_options: style[:render_options],
            rules: compile_rules(style[:rules], path_prefix: path_prefix),
            use_raw_value: style[:render_type] == 'progress_bar',
          }
        end
      end

      def to_number(val)
        return 0 if val.nil?
        `parseFloat(#{val}) || 0`
      end

      def value_blank?(val)
        return false if `#{val} === false`
        return true unless val
        return `typeof #{val} === 'string'` ? val.strip.empty? : false
      end

      def detect_value_type(value)
        return 'string' if value.nil?
        value_str = value.to_s
        if value_str =~ /\A-?\d+\z/ && value_str !~ /\A0\d/
          'integer'
        elsif value_str =~ /\A-?\d+\.\d+\z/
          'float'
        elsif %w[true false].include?(value_str.downcase)
          'boolean'
        else
          'string'
        end
      end
    end
  end
end
