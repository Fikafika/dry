class RemoveJidFromVersions < ActiveRecord::Migration[8.0]
  def change
    ActiveRecord::Base.connection.tables.each do |table_name|
      next unless table_name.start_with?('d_') && table_name.end_with?('_versions')
      remove_column table_name, :jid, :string
    end
  end
end
