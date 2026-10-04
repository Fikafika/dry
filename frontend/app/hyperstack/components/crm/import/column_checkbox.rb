class Crm
  class Import
    class ColumnCheckbox < HyperComponent

      param :column
      param :col_key, default: "", type: String
      param :default_value, default: false

      render() do
        @check = column.attributes[col_key].nil? ? default_value : column.attributes[col_key]
        INPUT(class: 'box', type: 'checkbox', checked: @check) do
        end.on(:change) do |evt|
          mutate column.attributes[col_key] = !@check
        end
      end

    end

  end
end
