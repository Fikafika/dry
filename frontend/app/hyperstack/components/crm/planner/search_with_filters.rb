class Crm
  class Planner
    class SearchWithFilters < HyperComponent
      param :default_value, default: ''
      param :filter_present, default: false
      param :modal_target

      fires :search_changed

      render do
        filter_button_class = filter_present ? 'btn-primary' : 'btn-outline-secondary'
        DIV(class: 'input-group input-group-sm') do
          INPUT(
            type: :text,
            class: 'form-control',
            defaultValue: default_value,
            title: I18n.t('crm.planner.filters.search_tooltip'),
            placeholder: I18n.t('crm.planner.filters.placeholder'),
          ).on(:input) do |evt|
            search_changed!(evt.target.value) if evt.target.value.blank?
          end.on(:key_down) do |evt|
            search_changed!(evt.target.value) if evt.key == 'Enter'
          end
          DIV(class: 'input-group-append') do
            BUTTON(
              class: "btn #{filter_button_class}",
              'data-toggle': 'modal',
              'data-target': modal_target,
              title: I18n.t('crm.planner.filters.advanced')
            ) do
              I(class: 'fa fa-filter')
            end
          end
        end
      end
    end
  end
end