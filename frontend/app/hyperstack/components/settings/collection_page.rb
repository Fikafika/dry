class Settings::CollectionPage < ::Stackable::Page
  include Hyperstack::Router::Helpers

  param :klass
  param :resource_id_key
  param :editable, default: false
  param :path_prefix, type: String, default: ''
  param :includes_for_all, default: {}
  param :location
  param :location_suffix, default: ''
  param :default_icon, default: 'square far'

  collect_other_params_as :others

  before_mount do
    @current_model = nil
    @counts = nil
    @counts_loading = false
  end

  before_update do
    @current_model = nil
  end

  render { content }

  def content
    @resource_id = request.params[resource_id_key]
    layout do
      Stackable::Toolbar() do
        Stackable::PageHeader(title: list_title, back: back_location) do
          action_menu
        end
      end
      Stackable::List({
        active: current_item.try(:[], :id),
        items: items,
        location: location
      })
      Stackable::AddButton(href: location + '/new') if editable
    end
  end

  def back_location
    r = location.split('/')
    r.pop
    return r.join('/')
  end

  def list_title
    klass&.model_name&.human(count: 2)
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
    others[:scope_for_all] || request.params
  end

  def model_to_item(model)
    return nil unless model
    return {
      id: model.class.api_id(model) + location_suffix,
      icon: model.try(:icon) || model.class.try(:icon) || default_icon,
      title: model.try(:human_name) || model.try(:name),
    }
  end

  def current_model
    return @current_model if @current_model
    return unless resource_id && ['index', 'show'].include?(request.params[:action])
    @current_model = models.detect{|r| r.class.has_api_id?(r, resource_id)}
    return @current_model
  end

  def resource_id
    @resource_id ||= request.params[resource_id_key]
  end

  def action_menu
    return unless editable
    DIV(class: 'dropdown') do
      BUTTON(class: "btn btn-transparent-light-yiq shadow-none dropdown-toggle dropdown-toggle-ellipsis", type: "button", 'data-toggle': "dropdown") do
      end
      DIV(class: 'dropdown-menu dropdown-menu-right') do
        action_menu_items
      end
    end
  end

  def action_menu_items
    item_delete
  end

  def item_delete
    A(href: '#', class: 'dropdown-item text-capitalize-first-letter') do
      I18n.t('shared.delete')
    end.on(:click) do |event|
      event.prevent_default
      Modal.confirm(title: I18n.t('shared.delete')) do
        l = location_after_delete
        current_model.destroy.then do |response|
          if response[:success]
            App.history.replace(l)
          end
        end
      end
    end
  end

  def location_after_delete

    if models[0] == current_model
      next_model = models[1]
    elsif models[-1] == current_model
      next_model = models[-2]
    else
      i = models.to_a.index(current_model)
      next_model =  models[i + 1]
    end

    if next_model
      return location + '/' + next_model.class.api_id(next_model)
    else
      return location
    end
  end

  def should_component_update?(next_props, next_state)
    if @resource_id != request.params[resource_id_key]
      return true
    end
    return super
  end

end
