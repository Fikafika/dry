# frozen_string_literal: true

class AdaptMenuItemsToLayouts < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      schema.load
      ['list', 'kanban', 'dashboard'].each do |mode|
        schema.const::R::Menu::Item.where(['link LIKE ?', "%/#{mode}/%"]).find_each do |item|
          next unless item.link =~ /\/crm\/[^\/]*\/#{mode}/

          link = item.link.split('/')
          klass_name = klass_name_from_route_key(schema, link[4])
          next unless klass_name

          item_ = item if mode == 'dashboard'

          item.link =~ /[?&]l=([^&]*)/
          layout_id = $1
          l = find_or_create_layout(schema, klass_name, mode, item_, layout_id)
          next unless l

          new_link = item.link.gsub(/(?<prefix>\/crm\/[^\/]*)\/#{mode}/, '\k<prefix>/table')
          new_link.gsub(/[?&]u=([^&]*)/, '')
          if new_link =~ /[&?]l\=/
            if layout_id != l.id
              # ???
            end
          else
            sep = new_link.include?('?') ? '&' : '?'
            new_link = "#{new_link}#{sep}l=#{l.id}"
          end

          item.update(link: new_link)
        end
      end
    end
  end

  def klass_name_from_route_key(schema, route_key)
    return unless route_key
    return schema.const.const_klasses_by_route_key[route_key]&.name
  end

  def find_or_create_layout(schema, klass_name, mode, item, layout_id)
    result = @layouts&.dig(schema.name, klass_name, mode, item&.id)
    return result if result
    @layouts ||= {}
    @layouts[schema.name] ||= {}
    @layouts[schema.name][klass_name] ||= {}
    @layouts[schema.name][klass_name][mode] ||= {}
    @layouts[schema.name][klass_name][mode][item&.id] ||= {}

    l = schema.layouts.with_action('index').find_by(id: layout_id) if layout_id

    case mode
    when 'dashboard'
      unless l
        dashboard = schema.const::R::Dashboard.where(item_id: item.id).first
        # dashboard specific to a user
        if dashboard
          layout_ids = schema.layouts.with_action('index').where(klass_name: klass_name, default: false).select(:id).map(&:id)
          l = Dynamic::Layout::Element.where(component: 'Crm::Dashboard', layout_id: layout_ids).where(["component_params#>>'{record_id}'=?", dashboard.id]).first&.layout
          unless l
            l = schema.layouts.create!(
              human_name_fr: "#{i18n[mode][:fr]}",
              human_name_en: "#{i18n[mode][:en]}",
              actions: ['index'],
              klass_name: klass_name,
              default: false,
              updated_when_schema_is_changed: true,
              elements_attributes: [{
                component: 'Crm::Dashboard',
                component_params: {record_id: dashboard.id},
                component_params_converter_type: 'Crm::Index::Base::ParamsConverter',
              }],
            )
          end
        end
      end
    when 'kanban'
      if l
        e = l.elements.first
        if e.component == 'Crm::Kanban::View'
          e.update(component: 'Crm::Kanban')
          e.update(component_params_converter_type: 'Crm::Index::Base::ParamsConverter')
        end
      else
        l = schema.layouts.with_action('index').where(name: mode, klass_name: klass_name, default: true).first
        unless l
          l = schema.layouts.create!(
            human_name_fr: i18n[mode][:fr],
            human_name_en: i18n[mode][:en],
            name: mode,
            actions: ['index'],
            klass_name: klass_name,
            default: true,
            updated_when_schema_is_changed: true,
            elements_attributes: [{
              component: 'Crm::Kanban',
              component_params: {},
              component_params_converter_type: 'Crm::Index::Base::ParamsConverter',
            }],
          )
        end
      end
    else
      if l
        # convert ?
      else
        l = schema.layouts.with_action('index').where(name: mode, klass_name: klass_name, default: true).first
        unless l
          l = schema.layouts.create!(
            human_name_fr: i18n[mode][:fr],
            human_name_en: i18n[mode][:en],
            name: mode,
            actions: ['index'],
            klass_name: klass_name,
            default: true,
            updated_when_schema_is_changed: true,
            elements_attributes: [{
              component: "Crm::#{mode.classify}",
              component_params: {},
              component_params_converter_type: 'Crm::Index::Base::ParamsConverter',
            }],
          )
        end
      end
    end

    @layouts[schema.name][klass_name][mode][item&.id] = l
    return l
  end

  def i18n
    @translations ||= {
      'list' => {fr: 'Liste', en: 'List'},
      'kanban' => {fr: 'Kanban', en: 'Kanban'},
      'dashboard' => {fr: 'Tableau de bord', en: 'Dashboard'},
    }
  end

  def down
  end
end
