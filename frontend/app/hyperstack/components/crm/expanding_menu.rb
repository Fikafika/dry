# backtick_javascript: true

class Crm
  class ExpandingMenu < Base
    include OutsideOfRendering

    param :schema, default: nil
    param :offset, type: String, default: ''
    param :selected, default: nil

    render do
      observe schema
      DIV() do
        transition_duration = 0.3
        ExpandingSideBar(class: "expanding-side-bar-light-yiq d-none d-md-block") do
          SideMenu(id: 'crmexpandingmenu', menu: crm_menu, class: 'fixed-width', selected: selected)
        end
        dropdown
        editor
      end.on(:context_menu) do |event|
        next if event.ctrl_key || @show_menu_editor
        event.prevent_default
        show_dropdown(event)
      end
    end

    def show_dropdown(event)
      closest_item = event.target.closest('.list-group-item')
      @clicked_item = closest_item ? ::Element.find(closest_item.to_n) : nil
      @dropdown_position = {x: event.page_x, y: event.page_y}
      mutate
    end

    def dropdown
      return unless @dropdown_position
      ContextMenu(position: @dropdown_position) do
        Link('#', class: 'dropdown-item') do
          I(class: 'fas fa-pen fa-fw pr-3') {}
          I18n.t('crm.expanding_menu.dropdown.edit_menu')
        end.on(:click) do |event|
          event.prevent_default
          open_editor
        end
        if @clicked_item
          Link('#open_new_tab', class: "dropdown-item") do
            I(class: 'fas fa-share-square fa-fw pr-3') {}
            I18n.t('crm.expanding_menu.dropdown.open_new_tab')
          end.on(:click) do |event|
            event.prevent_default
            open_new_tab
          end
          Link('#copy_link', class: "dropdown-item") do
            I(class: 'fas fa-copy fa-fw pr-3') {}
            I18n.t('crm.expanding_menu.dropdown.copy_link')
          end.on(:click) do |event|
            event.prevent_default
            copy_link
          end
        end
      end.on(:hidden) do
        @dropdown_position = nil
      end
    end

    def open_editor
      @show_menu_editor = true
      @open_editor = true
      @dropdown_position = nil
      mutate
    end

    after_render do
      if @open_editor
        ::Element.find('#menu-editor-panel').modal()
        @open_editor = false
      end
    end

    def open_new_tab
      return unless @clicked_item
      href = @clicked_item.find('a').attr('href')
      `window.open(#{href}, '_blank')`
    end

    def copy_link
      return unless @clicked_item
      href = @clicked_item.find('a').attr('href')
      href = "#{App.location.protocol}://#{App.location.hostname}#{href}" if href.start_with?("/")
      `navigator.clipboard.writeText(#{href})`
    end

    def editor
      return unless @show_menu_editor
      SidePanel(id: 'menu-editor-panel', side: 'left', size: 'md', backdrop: true) do
        DIV(class: 'overflow-auto' ) do
          MenuEditor(menu: schema_menu, item_id: @clicked_item&.data('item_id')).on(:close) do
            ::Element.find('#menu-editor-panel').modal('hide')
          end
        end
      end.on(:close) do
        close_editor
      end
    end

    def close_editor
      @show_menu_editor = false
      after(0.5) do
        mutate
      end
    end

    def crm_menu
      result = []
      schema_menu&.roots&.each do |item|
        result << convert_item(item) if item.new_record? || item.permitted
      end

      if schema && User.current&.admin?(schema.name)
        result << {text: I18n.t("crm.settings"), icon: "cogs", target: "/crm/#{schema&.name&.underscore}/settings"}
      end

      result
    end

    def convert_item(item)
      a = []
      if item.sub_menu.length > 0
        item.sub_menu.each do |sub_m|
          a << convert_item(sub_m)
        end
      end
      {
        text: item.label || '',
        icon: item.icon || 'table',
        menu: a,
        state: '',
        target: item.link || '',
        attrs: {'data-item_id': item.id},
      }
    end

    def schema_menu
      observe User.current.menus.merge_where(schema_name: schema_name, name: 'crm').first
    end
  end

end
