class Crm
  class Datatable
    module RecordFromCell; extend ActiveSupport::Concern

      def record_id(cell)
        td = cell.element

        parent_td_of_cell = self.parent_td(cell)
        if outside_of_td_of_sub_table?(cell)
          td = parent_td_of_cell.children.find('td').last
          return nil if td.length == 0
        end

        column_name = cell.table.column(parent_td_of_cell).name
        path = column_name.to_s.split('.')
        if path.length > 1 || path.last&.end_with?('[]')
          path.pop
          path << 'id'
          nums = ::Element.find(td).data('nums').to_s.split(',').map(&:to_i) || []

          r = cell.table.row(parent_td_of_cell.parent).data()
          path.each do |attr|
            return nil unless r && attr
            if attr.end_with?('[]')
              i = nums.shift
              return nil unless i
              a = r[attr.gsub('[]', '')]
              return nil unless a
              r = a[i]
            else
              r = r[attr]
            end
          end

        else
          d = cell.table.row(td.parent).data
          r = d['id'] if d
        end
        return r
      end

      def parent_td(cell)
        td = cell.element
        result = td.closest('.sub_table').closest('td')
        result = td if result.length == 0
        return result
      end

      def outside_of_td_of_sub_table?(cell)
        td = cell.element
        sub_table = td.closest('.sub_table')
        return false if sub_table.length == 0
        parent_td_of_sub_table = sub_table.closest('td')
        return parent_td_of_sub_table.length == 0 && td.find('.sub_table').length != 0
      end
    end
  end
end
