class ChangeDynamicSchemaKlassesDependenciesFromFormulasFromYamlToJson < ActiveRecord::Migration[8.0]
  def change
    remove_column :dynamic_schema_klasses, :dependencies_from_formulas
    change_table :dynamic_schema_klasses do |t|
      t.json :dependencies_from_formulas, :json, default: {}
    end
  end
end
