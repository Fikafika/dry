require 'components/crm'

class Crm
  class Kanban
    class Column < HyperComponent

      param :column_name
      param :ticket_count, default: 0
      param :count_render, default: nil
      param :opened, default: nil

      fires :toggle_column

      def toggle_column
        toggle(:opened_column)
        toggle_column!(@opened_column)
      end

      after_new_params do
        @opened_column = opened
      end

      def css_classes
        if @opened_column
          { column: "kanban-column", icon: "fa fa-chevron-down" }
        else
          { column: "kanban-column-reverse", icon: "fa fa-chevron-right" }
        end
      end

      render do
        @css_classes = css_classes
        DIV(class: @css_classes["column"]) do
          DIV(class: "kanban-column-header") do
            DIV(class: "kanban-column-title") do
              P(class: "text-capitalize-first-letter") do
                column_name
              end
              SPAN(class: "fa fa-file") do
                if count_render
                  count_render.call
                else
                  SPAN { ticket_count }
                end
              end
            end
            SPAN(class: @css_classes["icon"])
          end.on('click') do
            toggle_column
          end
          DIV(class: "kanban-column-content") do
            children.each do |child|
              child.render
            end
          end
        end
      end
    end
  end
end
