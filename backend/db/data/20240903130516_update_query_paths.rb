class UpdateQueryPaths < ActiveRecord::Migration[6.0]
  def up
    Dynamic::Schema.find_each do |schema|
      schema.load
      menu_klass = schema.const::R::Menu
      query_klass = schema.const::R::Query::Current
      #schema.const::R::Query::Saved (We keep paths for queries of the 'saved' type.)
      updated_query_ids = Set.new
      new_query_ids = Set.new

      menu_klass.find_each do |menu|
        menu.items.find_each do |item|
          link = item.link
          next unless link
          base_link = link.gsub(/\/search.*$|\/last_search.*$/, '')
          next if base_link.include?('/kanban/')

          query_klass.transaction do
            found_current_queries = query_klass.where("user_id = ? AND path LIKE ?", menu.user_id, "%#{base_link}%")
            found_current_queries.find_each do |query|
              next if query.path.include?(item.id) || new_query_ids.include?(query.id)
              path_parts = query.path.split('/')
              if updated_query_ids.include?(query.id)
                path_parts[0]="#{item.id}:"
                new_query = query_klass.create!(path: path_parts.join('/'), params: query.params, original_id: query.original_id, type: query.type, user_id: menu.user_id)
                new_query_ids.add(new_query.id)
              else
                query.update_column(:path, path_with_item_id(path_parts, item.id))
                updated_query_ids.add(query.id)
              end
            end
          end

        end
      end
    end
  end

  def down
    Dynamic::Schema.find_each do |schema|
      schema.load
      menu_klass = schema.const::R::Menu
      query_klass = schema.const::R::Query::Current
      # schema.const::R::Query::Saved (We keep paths for queries of the 'saved' type.)
      updated_query_paths = Set.new

      menu_klass.find_each do |menu|
        menu.items.find_each do |item|
          link = item.link
          next unless link
          base_link = link.gsub(/\/search.*$|\/last_search.*$/, '')
          link_parts = base_link.split('/')
          next if link_parts[3] == 'kanban'

          link_parts[0] = '' unless link_parts[3] == 'dashboard'
          base_link = link_parts.join('/')
          query_klass.transaction do
            found_current_queries = query_klass.where("user_id = ? AND path LIKE ?", menu.user_id, "%#{base_link}%")
            found_current_queries.find_each do |query|
              if query.path.include?(item.id)
                path_parts = query.path.split('/')
                new_path = path_without_item_id(path_parts, item.id, menu.user_id)
                if updated_query_paths.include?(new_path)
                  query.destroy!
                else
                  query.update_column(:path, new_path)
                  updated_query_paths.add(query.path)
                end
              end
            end
          end
        end
      end
    end
  end

  private

  def path_with_item_id(path_parts, item_id)
    if path_parts[3] == 'dashboard'
      path_parts[0]="#{item_id}:"
      return path_parts.join('/')
    else
      "#{item_id}:#{path_parts.join('/')}"
    end
  end

  def path_without_item_id(path_parts, item_id, user_id)
    if path_parts[3] == 'dashboard'
      path_parts[0]="#{user_id}:"
      return path_parts.join('/')
    else
      path_parts.join('/').gsub("#{item_id}:", '')
    end
  end
end
