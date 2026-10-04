class SideMenu < HyperComponent

  param :id, default: nil
  param :menu, default: nil
  param :selected, default: nil

  collect_other_params_as :other_params

  render() do
    build_menus(id, menu)
  end

  def build_menus(id, menu, depth = 0)
    return unless menu.try(:any?) || depth == 0
    build_menu(id, menu, depth)
  end

  def build_menu(id, menu, depth = 0)
    UL(class: "list-group flex-column d-flex flex-column depth-#{depth} px-0 overflow-auto") do
      menu.each do |m|
        if selected?(m)
          m = m.merge(selected: true)
        end
        Button(m) do
          if m[:menu]
            build_menus("#{menu_id(id, m)}", m[:menu], depth + 1)
          end
        end
      end
    end
  end

  def menu_id(id, m)
    "#{id}-#{m[:text].gsub(/\s/, '-')}"
  end

  def selected?(m)
    return false unless selected
    item_id = m.dig(:attrs, 'data-item_id')
    if item_id
      r = item_id == selected
    else
      r = m[:target].present? && selected.start_with?(m[:target])
    end
    return r || m[:menu]&.detect{|m_| selected?(m_)}
  end

  class Button < HyperComponent
    include Hyperstack::Router::Helpers
    include UrlHelper

    param :icon, default: ''
    param :text, default: ''
    param :target, default: ''
    param :icon_size, default: '2x'
    param :selected, default: false

    collect_other_params_as :other_params

    render() do
      LI({class: 'list-group-item d-flex px-0 py-0'}.merge(attrs)) do
        css_class = "btn text-left d-flex flex-row justify-content-start align-items-center py-2 shadow-none rounded-0 #{'btn-primary' if selected}"
        Link(add_param_to_url(target, 'mi', attrs["data-item_id"]), class_name: css_class) do
          if icon.present?
            DIV(class: "fa fa-#{icon} fa-#{icon_size} fa-fw")
          end
          SPAN(class: "pl-2") do
            text
          end
        end
        children.each(&:render)
      end

    end

    def attrs
      other_params[:attrs] || {}
    end

  end

end
