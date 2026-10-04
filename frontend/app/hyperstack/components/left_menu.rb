# backtick_javascript: true

class LeftMenu < ::HyperComponent

  render do
    AppMenu(
      id: 'left-menu',
      desktop: desktop,
      mobile: mobile,
    ).on(:open) do
      @open = true
      mutate
    end.on(:close) do
      @open = false
    end
  end

  before_update do
    if menu_changed?
      @desktop = nil
      @mobile = nil
    end
  end

  def desktop
    return unless open?
    return @desktop if @desktop
    result = []
    result << apps
    result << communities if schema_name
    @desktop = result
    return result
  end

  def mobile
    return unless open?
    return @mobile if @mobile
    result = []
    result << crm if schema_name
    result << apps
    result << communities if schema_name
    @mobile = result
    return result
  end

  def menu_changed?
    return (schema_name_changed? || user_menu_changed? || sso_menu_changed?)
  end

  def open?
    @open
  end

  def apps
    {id: 'apps', text: I18n.t('left_menu.apps'), icon: 'desktop', target: '', menu: apps_items}
  end

  def apps_items
    return [] unless sso_menu
    sso_menu.applications.select{|a| a.application_name != 'dynamo_settings' || User.current.admin?(schema_name) }.map{|a| app_item(a)}
  end

  def sso_menu
    observe Sso::Menu.where(service: service, community: schema_name).first
  end

  def sso_menu_changed?
    result = (@previous_sso_menu != sso_menu)
    @previous_sso_menu = sso_menu if sso_menu&.loaded?
    result
  end

  def app_item(a)
    {
      text: a.human_name,
      icon: I18n.t("icons.apps.#{a.application_name}", default: 'square'),
      target: target(a),
      external: external?(a),
    }
  end

  def service
    `window.location.pathname` =~ /^settings/ ? "#{host}/settings" : "#{host}/crm"
  end

  def host
    "#{`window.location.protocol`}//#{`window.location.host`}"
  end

  def target(a)
    external?(a) ? a.uri : a.uri.gsub(host, '')
  end

  def external?(a)
    !(a.uri.start_with?(host) && a.application_name =~ /dynamo/)
  end

  def communities
    {id: 'communities', text: I18n.t('left_menu.communities'), icon: 'users', target: '', menu: communities_items}
  end

  def communities_items
    result = []
    return result unless sso_menu
    if sso_menu.hosts.length == 1
      return sso_menu.hosts.first.communities.select{|c| c.application}.map do |c|
        community_item(c)
      end
    else
      sso_menu.hosts.each do |h|
        m = h.communities.select{|c| c.application}.map do |c|
          community_item(c)
        end
        result << {
          text: h.human_name,
          type: 'group',
          menu: m
        } if m.any?
      end
    end
    return result
  end

  def community_item(c)
    {
      text: c.name,
      icon: 'users',
      target: target(c.application),
      external: external?(c.application),
      image: c.logo_path,
    }
  end

  def crm
    {id: 'crm', text: I18n.t('left_menu.crm'), icon: 'table', target: '', menu: crm_menu}
  end

  def crm_menu
    result = []
    user_menu&.roots&.each do |item|
      result << convert_user_menu_item(item) if item.permitted
    end

    result << {text: I18n.t("crm.settings"), icon: "cogs", target: "/crm/#{schema_name}/settings"} if User.current.admin?(schema_name)

    result
  end

  def convert_user_menu_item(item)
    a = []
    if item.sub_menu.length > 0
      item.sub_menu.each do |sub_m|
        a << convert_user_menu_item(sub_m)
      end
    end
    {
      text: item.label || '',
      icon: item.icon || 'table',
      menu: a,
      state: '',
      target: item.link,
      attrs: {'data-item_id': item.id},
    }
  end

  def user_menu
    observe User.current.menus.merge_where(schema_name: schema_name, name: 'crm').first
  end

  def user_menu_changed?
    result = (@previous_user_menu != user_menu)
    @previous_user_menu = user_menu if user_menu&.loaded?
    result
  end

  def schema_name
    request.params[:schema] || request.params[:schema_id]
  end

  def schema_name_changed?
    result = (@previous_schema_name != schema_name)
    @previous_schema_name = schema_name
    return result
  end

end
