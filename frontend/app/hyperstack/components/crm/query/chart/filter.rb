class Crm
  module Query
    module Chart
      class Filter < Form::Element::Base

        param :chart
        param :klass

        render { content }

        def render_input
          return unless klass

          observe klass.options_for_indexed_json
          layout_input do
            if klass.options_for_indexed_json.loaded?
              value = form.submission.read(path)
              ::Crm::Chart::Filter.create_element(value: value&.dup, klass: klass, chart: chart).on(:change) do |v|
                change_value(v)
                mutate
              end
            end
          end
        end

        def displayed_label
          I18n.t("crm.query.params.chart.#{attribute_name}")
        end

      end
    end
  end
end
