# backtick_javascript: true

require 'components/form/element/attribute/date_time'

#TODO improve this widget to manage other cron features
class Form
  module Element
    module Attribute

      class Cron < ::Form::Element::Attribute::DateTime

        render { content }

        def input_value
          return unless form.submission.read(path)
          m = `moment(#{form.submission.read(path)}, "m H D M")`
          unless datetimepicker_initialized?
            @current_value ||= form.submission.read(path)
          end

          if datetimepicker_initialized? || !`#{m}.isValid()`
            result = @current_value
          else
            result = `#{m}.format(#{display_format})`
            if result == 'Invalid date'
              result = @current_value
            end
          end
          @current_value = result

          result
        end

        def convert_value(value)
          return if nullify? && value == ''
          return value unless value
          if is_cron_string?(value)
            return value
          else
            d = `moment(#{value})`
            if `d.isValid()`
              return `#{d}.format("m H D M")`
            end
            return nil
          end
        end

        def is_cron_string?(s)
          s.class.name == "String" && !!(s =~ /(@(annually|yearly|monthly|weekly|daily|hourly|reboot))|(@every (\d+(ns|us|µs|ms|s|m|h))+)|((((\d+,)+\d+|(\d+(\/|-)\d+)|\d+|\*) ?){5,7})$/)
        end

      end
    end
  end
end
