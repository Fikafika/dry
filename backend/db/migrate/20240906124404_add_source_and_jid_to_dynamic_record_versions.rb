class AddSourceAndJidToDynamicRecordVersions < ActiveRecord::Migration[6.0]
  def change
    ActiveRecord::Base.connection.tables.each do |table_name|
      next unless table_name.start_with?('d_') && table_name.end_with?('_versions')
      change_table table_name do |t|
        unless ActiveRecord::Base.connection.column_exists?(table_name, :source)
          t.integer :source
          t.string :jid
        end
      end
    end
  end
end
