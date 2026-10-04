require 'components/settings/edit_panel'

class Settings::Base < ::Stackable::Container
  include Hyperstack::Router::Helpers
  include WindowTitle
  include RenderForAdmin

  param :path_prefix, type: String, default: ''

  before_update do
    if mandatory_resources.detect{|r| r.try(:not_found?) }
      App.history.push(base_location)
    end
  end

  def observe_models
    @current_model = nil
    observe models
  end

  render{ content }

  def content
    observe_models
    update_recents
    layout(layout_page_count) do
      if request.params[:action] == 'index'
        parent_parent_page
        parent_page(active: resources_name)
        list_page
      else
        parent_page(active: resources_name)
        list_page
        edit_page
      end
    end
  end

  def page_title
    I18n.t("crm.settings")
  end

  def layout_page_count
    r = App.location.pathname.split('/')
    r.pop
    return r.last == 'settings' ? 2 : 3 # no better way to compute that ?
  end

  def parent_parent_page(params = {})
  end

  def parent_parent_location_suffix
    '/' + App.location.pathname.split('/').last
  end

  def parent_page(params = {})
    settings_page(params)
  end

  def settings_page(params)
    ::Stackable::Page(col: params[:col]) do
      ::Stackable::Toolbar() do
        ::Stackable::PageHeader(title: I18n.t('settings.administration'))
      end
      ::Stackable::List({
        active: params[:active],
        items: [
          ::Dynamic::Schema,
        ].map do |a|
          {
            id: 'schemas',
            icon: a.try(:icon) || default_icon,
            title: a.model_name.human(count: 2),
          }
        end,
        location: base_location
      })
    end
  end

  def list_page
    CollectionPage(
      klass: klass,
      resource_id_key: resource_id_key,
      path_prefix: path_prefix,
      location: index_location,
      scope_for_all: scope_for_all,
      includes_for_all: includes_for_all,
      editable: editable?,
    )
  end

  def editable?
    true
  end

  def self.resources_name(klass = self, plural = true)
    return @resources_name if @resources_name && klass == self

    result = (klass.name.end_with?('::Base') ? klass.parent  : klass).name.demodulize.underscore
    result = result.pluralize if plural

    @resources_name = result if klass == self

    return result
  end

  def resources_name
    self.class.resources_name
  end

  def self.resource_id_key
    :"#{self.resources_name.singularize}_id"
  end

  def resource_id_key
    self.class.resource_id_key
  end

  def index_location
    "#{back_location}/#{resources_name}"
  end

  def base_location
    interpolate_path(path_prefix, match.params)
  end

  def back_location
    base_location
  end

  def location(current = current_model)
    [index_location, current ? current_model.class.api_id(current) : nil].compact.join('/')
  end

  def current_model
    @current_model = @current_model._replaced_by if @current_model&._replaced_by # for polymorphism
    return @current_model if @current_model

    case match.params[:action]
    when 'new'
      @current_model = new_record
    when 'show'
      @current_model = klass ? klass.includes(includes_for_show).where(scope_for_show).find(match.params[resource_id_key]) : nil
    when 'edit'
      @current_model = klass ? klass.includes(includes_for_edit).where(scope_for_edit).find(match.params[resource_id_key]) : nil
    when 'index'
    end

    observe @current_model if @current_model

    return @current_model
  end

  def new_record
    klass.new
  end

  def edit_page
    ::Stackable::LargePage() do
      if current_model
        edit_panel
      end
    end
  end

  def items
    models.map{|model| model_to_item(model) }
  end

  def current_item
    model_to_item(current_model)
  end

  def klass
  end

  def models
    if klass
      observe result = klass.order(order_for_all).includes(includes_for_all).where(scope_for_all).per(1000).all
    else
      result = []
    end
    return result
  end

  def order_for_all
    klass.instance_methods.include?(klass.name_attribute) ? {klass.name_attribute.to_sym => :asc} : {id: :asc}
  end

  def scope_for_all
    match.params
  end

  def scope_for_show
    scope_for_all
  end

  def scope_for_edit
    return {} unless match.params
    match.params.except(resource_id_key, 'action').to_h
  end

  def self.includes_for_all
    {}
  end

  def self.includes_for_show
    includes_for_all
  end

  def self.includes_for_edit
    {}
  end

  def includes_for_all
    self.class.includes_for_all
  end

  def includes_for_show
    self.class.includes_for_show
  end

  def includes_for_edit
    self.class.includes_for_edit
  end

  def order_for_all
    klass.instance_methods.include?(klass.name_attribute) ? {klass.name_attribute.to_sym => :asc} : {id: :asc}
  end

  def model_to_item(model)
    return nil unless model
    return {
      id: model.class.api_id(model),
      icon: model.try(:icon) || model.class.try(:icon) || default_icon,
      title: model.try(:human_name) || model.try(:name),
    }
  end

  def mandatory_resources
    []
  end

  def default_icon
    'square far'
  end

  def update_recents
    return unless request && request.params[:action] == 'show' && current_item
    recents = App.location.pathname.start_with?('/crm') ? Settings::Schema::Recents : Settings::Recents
    recents.add_entry(current_item.merge(path: App.location.pathname))
  end

  def edit_panel
    EditPanel(record: current_model, path: "#{index_location}/:id")
  end

  class EditPanel < ::Settings::EditPanel
  end

end
