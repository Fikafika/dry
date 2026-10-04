class MenuReplace < HyperComponent

  param :id, default: nil
  param :menu, default: nil

  render(DIV) do
    build_menus(id, menu)
  end

  def build_menus(id, menu, o = {show: true})
    return unless menu.try(:any?)

    build_menu(id, menu, o)

    menu.each do |m|
      build_menus(menu_id(id, m), m[:menu], {parent_id: id})
    end
  end

  def build_menu(id, menu, o = {})
    DIV(id: id, class: "collapse #{o[:show] ? 'show' : nil} width") do
      DIV(class: 'list-group') do
        IconButton(
          text: I18n.t('shared.back'),
          icon: 'chevron-left',
          target: [id, o[:parent_id]].compact.map{|t| "##{t}" }.join(','),
          toggle: 'collapse',
          class: 'shadow-none',
        ) if o[:parent_id]
        menu.each do |m|
          IconButton(
            text: m[:text],
            icon: m[:icon],
            right_icon: m[:menu] ? 'chevron-right' : nil,
            target: m[:menu] ?  "##{id}, ##{menu_id(id, m)}" :  m[:target],
            toggle: m[:menu] ? 'collapse' : nil,
            class: 'shadow-none',
          )
        end
      end
    end
  end

  def menu_id(id, m)
    "#{id}-#{m[:text].gsub(/\s/, '-')}"
  end

end
