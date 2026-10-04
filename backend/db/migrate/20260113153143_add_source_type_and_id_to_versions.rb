class AddSourceTypeAndIdToVersions < ActiveRecord::Migration[8.0]
  def change
    ActiveRecord::Base.connection.tables.each do |table_name|
      next unless table_name.start_with?('d_') && table_name.end_with?('_versions')
      add_column table_name, :source_type, :string
      add_column table_name, :source_id, :uuid
    end
  end
end
