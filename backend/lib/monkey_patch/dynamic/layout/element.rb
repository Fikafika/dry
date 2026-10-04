ActiveSupport.on_load(:dynamic_layout_element) do
  include MassAssignmentSkipUnknownAttributes

  before_create :create_dashboard, if: -> { component == 'Crm::Dashboard' && !(component_params && component_params['record_id'].present?) }

  def create_dashboard
    dashboard = dashboard_klass.create!(
      human_name_fr: layout.human_name_fr.present? ? layout.human_name_fr : 'Tableau de bord',
      human_name_en: layout.human_name_en.present? ? layout.human_name_en : 'Dashboard',
    )
    self.component_params ||= {}
    self.component_params['record_id'] = dashboard.id
  end

  def dashboard_klass
    return unless layout
    r = "D::#{layout.schema.name}::R::Dashboard".safe_constantize
    unless r
      layout.schema.load
      r = "D::#{layout.schema.name}::R::Dashboard".safe_constantize
    end
    r
  end

  after_destroy :destroy_dashboard, if: -> { component == 'Crm::Dashboard' && component_params && component_params['record_id'].present? }

  def destroy_dashboard
    return unless dashboard_klass
    dashboard = dashboard_klass.find_by_id(component_params['record_id'])
    dashboard&.destroy
  end

  attr_accessor :duplicate_related_records

  before_create :duplicate_dashboard, if: -> { duplicate_related_records && component == 'Crm::Dashboard' && component_params && component_params['record_id'].present? }

  def duplicate_dashboard
    return unless dashboard_klass
    dashboard = dashboard_klass.find_by_id(component_params['record_id'])

    attrs = dashboard.attributes_for_duplicate
    attrs[:user_id] = menu_item_user_id
    new_dashboard = dashboard_klass.create!(attrs)

    component_params['record_id'] = new_dashboard.id
  end

  def menu_item_user_id
    return unless menu_item_klass && layout.menu_item_id
    return menu_item_klass.find_by_id(layout.menu_item_id)&.menu&.user_id
  end

  def menu_item_klass
    "D::#{layout.schema.name}::R::Menu::Item".safe_constantize
  end
end
