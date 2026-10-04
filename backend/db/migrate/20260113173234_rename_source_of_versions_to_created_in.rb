class RenameSourceOfVersionsToCreatedIn < ActiveRecord::Migration[8.0]
  def change
    ActiveRecord::Base.connection.tables.each do |table_name|
      next unless table_name.start_with?('d_') && table_name.end_with?('_versions')
      rename_column table_name, :source, :created_in
    end
  end
end
