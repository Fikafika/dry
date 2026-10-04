class Crm
  class Planner
    class View
      class ResourceLabelContent < HyperComponent

        param :title
        param :resource_id
        param :color
        param :has_conflict, default: false

        fires :color_picker_requested

        CIRCLE_DIAMATER_IN_PIXEL = 8

        render { content }

        def content
          SPAN(
            ref: -> (el) { @circle_element = el },
            class: circle_class,
            style: circle_style,
            data: { resource_id: resource_id }, 'data-toggle': 'tooltip',
            title: I18n.t('crm.planner.view.color_picker_title', title: title)
          ).on(:click) do |e|
            e.prevent_default
            color_picker_requested!(
              resource_id: resource_id,
              color: color,
              color_circle: @circle_element,
              mouse_x: e.JS[:native].JS[:clientX] + CIRCLE_DIAMATER_IN_PIXEL,
              mouse_y: e.JS[:native].JS[:clientY] + CIRCLE_DIAMATER_IN_PIXEL
            )
          end
          if has_conflict
            Crm::Planner::ConflictBadge(css_classes: 'text-warning mr-1 p-1', style: { position: 'static'})
          end
          SPAN(class: 'small') { title }
        end

        def circle_class
          "#{'bg-primary ' unless color}rounded-circle d-inline-block mr-3 cursor-pointer"
        end

        def circle_style
          result = {
            width: "#{CIRCLE_DIAMATER_IN_PIXEL}px",
            height: "#{CIRCLE_DIAMATER_IN_PIXEL}px",
          }
          result.merge!(backgroundColor: color) if color
          return result
        end
      end
    end
  end
end