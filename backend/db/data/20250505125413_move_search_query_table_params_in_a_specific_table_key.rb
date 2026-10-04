class MoveSearchQueryTableParamsInASpecificTableKey < ActiveRecord::Migration[8.0]
  def change
    Dynamic::Schema.find_each do |s|
      s.load
      change_queries(s)
      change_menu_items(s)
    end
  end

  def change_queries(schema)
    schema.const::R::Query::Base.find_each do |query|
      next unless query.params
      new_params = migrate_params(query.params)
      if query.params != new_params
        query.update(params: new_params)
      end
    end
  end

  def migrate_params(params)
    result = {}
    params.each do |k, v|
      case k
      when 'columns'
        result['table'] ||= {}
        result['table']['columns'] = v
      when 'order'
        result['table'] ||= {}
        result['table']['order'] = v
      when 'locked_column', 'locked'
        result['table'] ||= {}
        result['table']['locked'] = v
      when 'width', 'column_widths'
        result['table'] ||= {}
        result['table']['width'] = v
      when 'column_states'
        result['kanban'] ||= {}
        result['kanban']['column_states'] = v
      else
        result[k] = v
      end
    end
    return result
  end

  def change_menu_items(schema)
    like_values = ['order', 'locked', 'chart', 'column_states'].map{|e| "%#{e}%"}
    wheres = [like_values.map{'link LIKE ?'}.join(' OR ')] + like_values
    schema.const::R::Menu::Item.where('link LIKE ?', '%\?\_=%').where(*wheres).find_each do |item|
      parts = item.link.split(/\?_=|&/)
      rison_params = CGI.unescape(parts[1])
      begin
        parsed_rison_params = Rison.parse(rison_params)
        new_params = Rison.dump(migrate_params(parsed_rison_params))
        if new_params != rison_params
          parts[1] = new_params
          new_link = (["#{parts[0]}?_=#{new_params}"] + parts[2..-1]).join('&')
          item.update(link: new_link)
        end
      rescue Racc::ParseError => e
        puts "an error occure while migrating #{item.inspect}"
        puts e.message
      end
    end
  end
end
