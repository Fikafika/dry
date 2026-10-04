class CreateDynamicFormula < ActiveRecord::Migration[6.0]

  def change

    add_column :dynamic_schema_klasses, :dependencies_from_formulas, :string, default: {}.to_yaml
    add_column :dynamic_schema_attributes, :formula, :string
    add_column :dynamic_schema_associations, :formula, :string

  end

end
