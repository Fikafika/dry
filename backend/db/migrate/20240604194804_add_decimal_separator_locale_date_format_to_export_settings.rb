class AddDecimalSeparatorLocaleDateFormatToExportSettings < ActiveRecord::Migration[6.0]
  def change
    ActiveRecord::Base.connection.tables.each do |t|
      next unless t.start_with?('d_') && t.end_with?('_r_export_settings')
      add_column t, :decimal_separator, :string
      add_column t, :locale, :string
      add_column t, :date_format, :string
    end
  end
end
