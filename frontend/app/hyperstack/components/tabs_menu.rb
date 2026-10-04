class TabsMenu < HyperComponent

  param :menu, default: nil
  param :klasses, default: [], type:[Class]
  param :klass, default: nil

  fires :dismiss_modal

  render do
    DIV(class:"container") do
      DIV(class: "row") do
        DIV(class:"col-2 px-0") do
          UL(id: "tabs", class: "nav nav-tabs nav-fill flex-column", role: "tablist") do
            tabs_menu.each do |h|
              LI(class:"nav-item") do
                A(class: "btn w-100 border-0 rounded-0 btn-transparent-light-yiq #{(h[:id] == tabs_menu.first[:id]) ? 'active' : ''}", "data-toggle": "tab", href: "#menu-#{h[:id]}", role: "tab") do
                  SPAN(class: "fa fa-#{h[:icon]} fa-fw") do
                  end
                end
              end
            end
          end
        end
        DIV(class:"col-10 px-0") do
          DIV(class:"tab-content") do
            tabs_menu.each do |h|
              DIV(id: "menu-#{h[:id]}", class: "tab-pane fade #{(h[:id] == tabs_menu.first[:id]) ? 'show active' : ''} ", role:"tabpanel") do
                if h[:id] == 'apps'
                  MenuReplace(menu: menu)
                elsif h[:id] == 'tables'
                  MenuReplace(menu: crm_menu)
                else
                  puts "don't know this menu" #TODO: throw an error
                end
              end.on(:click) do
                dismiss_modal!
              end
            end
          end
        end
      end
    end
  end

  def tabs_menu
    [
      {id: 'tables', text: 'Tables', icon: 'table', target: ''},
      {id: 'apps', text: 'Apps', icon: 'desktop', target: ''},
    ]
  end

  def crm_menu
    result = []
    klasses.each do |k|
      result << {
        text: k.name.demodulize,
        icon: k.icon || 'table',
        menu: k.try(:menu),
        state: k.name == klass.name ? 'active' : '',
        target: klass_index_path(k),
      }
    end

    result << {text: I18n.t("crm.settings"), icon: I18n.t("icons.crm.settings"), target: "/crm/#{klass.parent.name.demodulize.underscore}/settings"} if klass
    result
  end

  def klass_index_path(klass)
    "/crm/#{klass.parent.name.demodulize.underscore}/table/#{klass.model_name.route_key}"
  end



end
