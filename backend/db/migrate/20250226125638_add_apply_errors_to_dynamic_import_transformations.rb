class AddApplyErrorsToDynamicImportTransformations < ActiveRecord::Migration[8.0]
  def change
    change_table :dynamic_import_transformations do |t|
      t.json :apply_errors, default: {}
    end
  end
end
