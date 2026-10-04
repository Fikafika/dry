class DashboardBelongsToItemId < ActiveRecord::Migration[6.0]
  def up
    Dynamic::Schema.find_each do |schema|
      schema.unload; schema.load

      item_klass = schema.const::R::Menu::Item
      dashboard_klass = schema.const::R::Dashboard
      item_klass.transaction do
        item_klass.find_each do |item|
          next unless item.link&.start_with?('/crm/')

          link_ = item.link.split('/')
          next unless link_[3] == 'dashboard'

          uri = URI.parse(item.link)
          query_params = Rack::Utils.parse_nested_query(uri.query)
          item_id_ = query_params.delete('u')
          uri.query = query_params.to_query
          uri.query = nil if query_params.empty?

          item.update_column(:link, uri.to_s)

          dashboard_name = schema.const.const_klasses_by_route_key[link_[4]]&.name&.demodulize

          next unless dashboard_name

          dashboard = dashboard_klass.find_by(name: dashboard_name, user_id: item_id_ || item.menu.user_id, item_id: nil)

          if dashboard
            dashboard.update_column(:item_id, item.id)
          else
            puts "Dashboard not found"
          end
        end
      end
    end
  end

  def down
    Dynamic::Schema.find_each do |schema|
      schema.unload; schema.load

      item_klass = schema.const::R::Menu::Item
      dashboard_klass = schema.const::R::Dashboard
      item_klass.transaction do
        item_klass.find_each do |item|
          next unless item.link&.start_with?('/crm/')

          link_ = item.link.split('/')

          next unless link_[3] == 'dashboard'

          uri = URI.parse(item.link)
          query_params = Rack::Utils.parse_nested_query(uri.query)
          query_params['u'] = item.menu.user_id
          uri.query = query_params.to_query

          item.update_column(:link, uri.to_s)

          dashboard_name = schema.const.const_klasses_by_route_key[link_[4]]&.name&.demodulize

          next unless dashboard_name

          dashboard = dashboard_klass.find_by(name: dashboard_name, user_id: item.menu.user_id, item_id: item.id)

          if dashboard
            dashboard.update_column(:item_id, nil)
          else
            puts "Dashboard not found for #{item.link}"
          end
        end
      end

      schema.features.find_by_name('Dynamic::Menu::Feature').update(dependency_order: nil)
    end
  end
end
