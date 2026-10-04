# backtick_javascript: true

require 'components/form/element/attribute/string'

class Form
  module Element
    module Attribute

      class Numeric < ::Form::Element::Attribute::String
        render { content }

        def read_only_displayed_value
          formatted_displayed_value(form.submission.read(path))
        end

        def edit_in_place_displayed_value
          read_only_displayed_value
        end

        def formatted_displayed_value(v)
          return nil if v.nil?
          method, options = format_method_for(record_klass, attribute_name)
          return v.to_s unless method
          send(method, v, options)
        end

        def input_args
          args = super
          if scaled?
            args[:value] = @typed_value || scaled_value(args[:value])
          end
          args
        end

        def change_value(value)
          return super unless scaled? && value.is_a?(::String)
          @typed_value = value
          super(stored_value(value))
        end

        def edit_in_place_original_value(event)
          return super unless scaled?
          @typed_value = nil
          form.submission.read(path)
        end

        def edit_in_place_submit_value(value)
          return super unless scaled?
          @typed_value = nil
          stored = stored_value(value)
          if @original_value == stored || (@original_value.blank? && stored.blank?)
            @edit = false
            mutate
            return
          end
          super(stored)
        end

        private

        def scaled?
          input_scale != 0
        end

        def input_scale
          return @input_scale if defined?(@input_scale)
          @input_scale =
            if record_klass.respond_to?(:attribute_format)
              UneekFormatting::Dynamic::AttributeFormatter.scale_for(record_klass.attribute_format(attribute_name))
            else
              0
            end
        end

        def scaled_value(v)
          return v if v.nil? || v == ''
          rounded_shift(v, input_scale)
        end

        def stored_value(v)
          return v if v.nil? || v == ''
          rounded_shift(v, -input_scale)
        end

        def rounded_shift(v, scale)
          shifted = UneekFormatting::NumberHelper.scale_number(v.to_f, scale)
          `parseFloat(#{shifted}.toPrecision(15))`
        end

      end

    end
  end
end
