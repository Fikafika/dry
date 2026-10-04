class ChangeCsvHeadersToOrderedCsvHeadersInExportSetting < ActiveRecord::Migration[6.0]
  def change
    ActiveRecord::Base.connection.tables.each do |t|
      next unless t.start_with?('d_') && t.end_with?('_r_export_settings')
      add_column t, :ordered_csv_headers, :json, default: {}, if_not_exists: true
      remove_column t, :csv_headers, if_exists: true
    end
  end
end
