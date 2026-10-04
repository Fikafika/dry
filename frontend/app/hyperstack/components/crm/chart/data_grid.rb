class Crm
  module Chart
    class DataGrid < Base
      render { content }

      [
        :section,
        :begin_slice,
        :end_slice,
        :size,
        :html,
        :html_section,
        :html_group,
        :sort_by,
        :order,
      ].each{|m| api_method(m) }

    end
  end
end


