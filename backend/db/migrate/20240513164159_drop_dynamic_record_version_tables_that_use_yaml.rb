class DropDynamicRecordVersionTablesThatUseYaml < ActiveRecord::Migration[6.0]
  def change
    ActiveRecord::Base.connection.tables.each do |table_name|
      next unless table_name.start_with?('d_') && table_name.end_with?('_versions')
      c = ActiveRecord::Base.connection.columns(table_name).detect{|c| c.name == 'object' }
      if c.type == :text
        ActiveRecord::Base.connection.drop_table(table_name)
      end
    end
  end
end
