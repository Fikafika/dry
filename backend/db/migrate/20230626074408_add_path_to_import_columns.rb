class AddPathToImportColumns < ActiveRecord::Migration[6.0]
  def change
    unless ActiveRecord::Base.connection.column_exists?(:dynamic_import_columns, :path)
      change_table :dynamic_import_columns do |t|
        t.text :path, default: [].to_yaml
      end
    end
  end
end
