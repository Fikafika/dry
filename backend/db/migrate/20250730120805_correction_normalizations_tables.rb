class CorrectionNormalizationsTables < ActiveRecord::Migration[8.0]
  def change
    drop_table :dynamic_schema_normalization_translations
    remove_column :dynamic_schema_normalizations, :name
  end
end
