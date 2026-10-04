class Crm
  module Chart
    class NumberDisplay < Base
      render { content }

      [
        :html,
        :format_number,
        :aria_live_region,
      ].each{|m| api_method(m) }

      [
        :value,
      ].each{|m| alias_method(m) }

      def default_settings
        return {
          pretransition: pretransition,
        }
      end

      def layout
        DIV(id: "chart-#{uuid}", class: "#{layout_padding} #{other_params[:className]} h-100 overflow-hidden d-flex flex-column", style: { containerType: "inline-size" }) do
          DIV(class: 'float-left position-relative w-100') do
            human_name_text
            buttons
          end

          DIV(class: 'clearfix')
          placeholder
          yield if block_given?

          DIV(class: "d-flex justify-content-center align-items-center flex-grow-1 w-100", style: { minHeight: 0, overflow: "hidden" }) do
            SPAN(class: "number-display", style: { fontSize: "30cqw", lineHeight: "1", whiteSpace: "nowrap"})
          end
          DIV(id: "chart-number-display-#{uuid}", class: "d-flex justify-content-center align-items-center w-100")
        end.on(:mouse_enter) do
          self.jq_node.find('.edit').show
          self.jq_node.find('.axis-sort').show
        end.on(:mouse_leave) do
          self.jq_node.find('.edit').hide
          self.jq_node.find('.axis-sort').hide
        end
      end

      def pretransition
        Proc.new do |chart|
          div_id = "chart-number-display-#{uuid}"
          `
            var div = document.getElementById(#{div_id});
            if (div && #{value} != null) {
              div.innerHTML = #{value};
            }
          `
        end.to_n
      end
    end
  end
end
