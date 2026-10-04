# backtick_javascript: true

class Form
  module Element
    module Attribute

      class DateTime < ::Form::Element::Attribute::Base
        render { content }

        INPUT_TYPES = {
          'year'   => 'number',
          'month'  => 'month',
          'day'    => 'date',
          'hour'   => 'datetime-local',
          'minute' => 'datetime-local',
          'second' => 'datetime-local',
        }.freeze

        INPUT_STEPS = {
          'year'   => 1,
          'hour'   => 3600,
          'minute' => 60,
          'second' => 1,
        }.freeze

        INPUT_BOUNDS = {
          'year'  => { min: '1000', max: '9999' },
          'month' => { min: '1000-01', max: '9999-12' },
        }.freeze

        UNCONSTRAINED_PRECISIONS = ['year', 'month'].freeze

        YEAR_FORMAT = 'YYYY'.freeze

        TOKEN_PATTERNS = {
          'YYYY' => '[0-9]{4}',
          'MM'   => '(0[1-9]|1[0-2])',
        }.freeze

        def input_args
          r = super
          r[:type] = input_type
          r[:defaultValue] = input_value if update_input_value?
          r.delete(:value)
          r[:step] = input_step if input_step
          r.merge!(INPUT_BOUNDS[precision]) if INPUT_BOUNDS[precision]
          if precision == 'month'
            r[:pattern] = input_pattern
            r[:placeholder] ||= input_placeholder
          end
          @value_changed_by_user = false
          return r
        end

        def unconstrained_input?
          return UNCONSTRAINED_PRECISIONS.include?(precision)
        end

        def input_placeholder
          return @input_placeholder if @input_placeholder
          result = input_format.gsub('YYYY', I18n.t('form.element.attribute.date.placeholder.year'))
          return @input_placeholder = result.gsub('MM', I18n.t('form.element.attribute.date.placeholder.month'))
        end

        def input_pattern
          @input_pattern ||= TOKEN_PATTERNS.inject(input_format) { |result, (token, pattern)| result.gsub(token, pattern) }
        end

        def input_format_matcher
          @input_format_matcher ||= Regexp.new("\\A#{input_pattern}\\z")
        end

        def input_type
          return INPUT_TYPES[precision] || 'datetime-local'
        end

        def input_step
          return INPUT_STEPS[precision]
        end

        def input_value
          return value if value
          return unless form.submission.read(path)
          m = `moment(#{form.submission.read(path)}, #{data_format})`
          r = `#{m}.format(#{input_format})`
          return r
        end

        def update_input_value?
          !@value_changed_by_user
        end

        def change_value(value)
          @value_changed_by_user = true
          return super(formatted_date(value)) if input_accepted?(value)
          return super(nil)
        end

        def input_accepted?(value)
          return true unless unconstrained_input?
          return true if value.blank?
          return input_format_matcher.match?(value)
        end

        def formatted_date(date_value)
          return nil unless date_value.present?
          `moment(#{date_value}, #{input_format}).format(#{data_format})`
        end

        def input_format
          case precision
          when 'year'   then return YEAR_FORMAT
          when 'month'  then return `moment.HTML5_FMT.MONTH`
          when 'day'    then return `moment.HTML5_FMT.DATE`
          when 'hour'   then return `moment.HTML5_FMT.DATETIME_LOCAL`
          when 'minute' then return `moment.HTML5_FMT.DATETIME_LOCAL`
          else               return `moment.HTML5_FMT.DATETIME_LOCAL_SECONDS`
          end
        end

        def data_format
          `moment.ISO-8601`
        end

        # read only --------------------------------------------------------------------------

        DEFAULT_PRECISION = 'second'.freeze

        def read_only_displayed_value
          v = form.submission.read(path)
          return nil unless v
          return formatted_value(v) || moment_format_displayed_value(v)
        end

        def formatted_value(value)
          method, options = UneekFormatting::Dynamic::AttributeFormatter.format_method_for_key(
            attribute_format, formatter_options, attribute_type_name
          )
          return nil unless method
          return UneekFormatting::Dynamic::AttributeFormatter.send(method, value, options)
        end

        def formatter_options
          return configured_precision ? { precision: configured_precision } : {}
        end

        def precision
          return configured_precision || default_precision
        end

        def configured_precision
          return other_params[:precision].presence || attribute_format_options[:precision].presence
        end

        def default_precision
          DEFAULT_PRECISION
        end

        def attribute_format_options
          return record_klass.try(:attribute_format_options, attribute_name) || {}
        end

        def attribute_type_name
          'DateTime'
        end

        def moment_format_displayed_value(v)
          m = `moment(#{v})`
          if `#{m}.isValid()`
            result = `#{m}.format(#{display_format})`
            if result == 'Invalid date'
              result = nil
            end
          end
          return result
        end

        def display_format
          I18n.t('format.date_time')
        end

        def edit_in_place_submit_value(value)
          return super(formatted_date(value)) if input_accepted?(value)
          return super(nil)
        end

      end
    end
 end
end
