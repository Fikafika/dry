class Crm
  module Chart
    class DataCount < Base
      render { content }

      [
        :html,
        :format_number,
        :crossfilter,
        :group_all,
      ].each{|m| api_method(m) }

    end
  end
end
