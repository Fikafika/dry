class AddLiberalParsingToImportSettingSource < ActiveRecord::Migration[6.0]
  def change
    change_table :dynamic_import_sources do |t|
      t.boolean :liberal_parsing, default: false
    end
  end
end
