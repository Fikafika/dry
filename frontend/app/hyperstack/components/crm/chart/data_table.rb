class Crm
  module Chart
    class DataTable < Base
      render { content }

      [
        :section,
        :size,
        :begin_slice,
        :end_slice,
        :columns,
        :sort_by,
        :order,
        :show_sections,
        :show_groups,
      ].each{|m| api_method(m) }

    end
  end
end
