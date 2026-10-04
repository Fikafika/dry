require 'components/form/element/attribute/serialized_array'

class Form
  module Element
    module Attribute
      class Array < SerializedArray
        render {content}

        def convert_value(value)
          super(value&.split('.'))
        end

        def tree_select_default_value
          super&.join('.')
        end

        class TreeSelectWithComputedOptions < SerializedArray::TreeSelectWithComputedOptions
        end

        class TreeSelect < SerializedArray::TreeSelect
        end
      end
    end
  end
end