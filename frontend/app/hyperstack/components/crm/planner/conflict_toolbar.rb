class Crm
  class Planner
    class ConflictToolbar < HyperComponent

      param :conflict_state

      fires :navigate

      render do
        conflicting_events = conflict_state.ids
        current_index = conflict_state.index
        has_conflicts = conflicting_events && conflicting_events.any?
        visibility_class = has_conflicts ? 'd-flex' : 'd-none'
        count = has_conflicts ? conflicting_events.length : 0
        safe_index = current_index || 0
        DIV(class: "justify-content-center align-items-center alert alert-warning py-1 mt-2 #{visibility_class}") do
          SPAN(class: 'mr-3') do
            I(class: 'fas fa-exclamation-triangle mr-2') {}
            I18n.t('crm.planner.conflicts.count', count: count)
          end
          is_first = safe_index == 0
          BUTTON(class: 'btn btn-sm btn-warning mr-1', disabled: is_first) do
            I(class: 'fas fa-chevron-left')
          end.on(:click) { navigate!(-1) }
          is_last = safe_index == (count - 1)
          BUTTON(class: 'btn btn-sm btn-warning mr-3', disabled: is_last) do
            I(class: 'fas fa-chevron-right')
          end.on(:click) { navigate!(1) }
          SPAN(class: 'small') do
            I18n.t('crm.planner.conflicts.current', current: safe_index + 1, total: count)
          end
        end
      end
    end
  end
end