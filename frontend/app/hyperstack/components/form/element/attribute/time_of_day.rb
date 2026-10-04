# backtick_javascript: true

require 'components/form/element/attribute/date_time'

class Form
  module Element
    module Attribute

      class TimeOfDay < ::Form::Element::Attribute::DateTime
        render { content }

        def input_value
          return form.submission.read(path)
        end

        def input_type
          'time'
        end

        def input_format
          `moment.HTML5_FMT.TIME_SECONDS`
        end

        def input_change_value(value)
          change_value(value)
        end

        def display_format
          I18n.t('format.time_of_day')
        end

        def formatted_date(date_value)
          moment_format_displayed_value(date_value)
        end

        # read only ------------------------------------------------------

        def read_only_displayed_value
          form.submission.read(path)
        end

        def moment_format_displayed_value(v)
          m = `moment(#{v}, #{display_format})`
          if `#{m}.isValid()`
            result = `#{m}.format(#{display_format})`
            if result == 'Invalid date'
              result = nil
            end
          end
          return result
        end
      end

    end
  end
end
