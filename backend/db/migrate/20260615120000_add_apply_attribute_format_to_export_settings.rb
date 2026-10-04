class AddApplyAttributeFormatToExportSettings < ActiveRecord::Migration[6.0]
  def change
    ActiveRecord::Base.connection.tables.each do |t|
      next unless t.start_with?('d_') && t.end_with?('_r_export_settings')
      add_column t, :apply_attribute_format, :boolean, default: false, null: false unless column_exists?(t, :apply_attribute_format)
    end
  end
end
