class Crm
  module Chart
    class SeriesChart < CompositeChart
      render { content }

      [
        :chart,
        :series_accessor,
        :series_sort,
        :value_sort,
      ].each { |m| api_method(m) }

    end
  end
end
