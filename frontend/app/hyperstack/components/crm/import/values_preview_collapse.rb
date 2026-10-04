class Crm
  class Import
    class ValuesPreviewCollapse < HyperComponent

      param :menu
      param :i

      render() do
        DIV(class: 'd-flex flex-row') do
          SPAN(class: 'd-flex flex-grow-1 text-truncate mr-2') do
            menu[0]&.truncate(30)
          end
          BUTTON(class: 'btn btn-light rounded-0 border-0', type: 'button', 'data-toggle': 'collapse', 'data-target': "#values_menu_#{i}", 'aria-expanded': 'true', 'aria-controls': 'advanced_params_menu') do
            SPAN(class: 'text-nowrap') do
              I18n.t('shared.show_more')
            end
          end
        end
        DIV(class: 'collapse container py-1 px-0', id: "values_menu_#{i}") do
          UL(class: 'list-group') do
            menu.each_with_index do |el, i|
              if i != 0
                LI(class: 'list-group-item p-1 text-left') do
                  el
                end
              end
            end
          end
        end
      end

    end
  end
end
