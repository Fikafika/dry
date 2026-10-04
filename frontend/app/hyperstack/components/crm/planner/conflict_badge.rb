class Crm
  class Planner
    class ConflictBadge < HyperComponent
      param :style, default: {}
      param :css_classes, default: ''

      render do
        SPAN(
          class: "#{css_classes}",
          style: combined_style,
          title: I18n.t('crm.planner.conflicts.view.conflict_title')
        ) do
          I(class: 'fas fa-exclamation-triangle')
        end
      end

      private

      def combined_style
        default_style = {
          position: 'absolute',
          top: '0px',
          right: '1px',
          zIndex: 10,
          fontSize: '13px'
        }
        default_style.merge(style)
      end
    end
  end
end