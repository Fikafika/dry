class AddCsvHeadersFilenameToExportSetting < ActiveRecord::Migration[6.0]
  def change
    ActiveRecord::Base.connection.tables.each do |t|
      next unless t.start_with?('d_') && t.end_with?('_r_export_settings')
      add_column t, :csv_headers, :string, array: true, default: [] unless column_exists?(t, :csv_headers) # Rails <6.1
      add_column t, :filename, :string unless column_exists?(t, :filename) # Rails <6.1
    end
  end
end
