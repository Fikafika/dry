# backtick_javascript: true

require 'components/form/element/attribute/date_time'

class Form
  module Element
    module Attribute

      class Date < ::Form::Element::Attribute::DateTime
        render { content }

        DEFAULT_PRECISION = 'day'.freeze

        def default_precision
          DEFAULT_PRECISION
        end

        def attribute_type_name
          'Date'
        end

        def display_format
          I18n.t('format.date')
        end

        def data_format
          `moment.HTML5_FMT.DATE`
        end

      end

    end
  end
end
