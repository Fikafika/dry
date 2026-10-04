class AddAccessFormulaToForms < ActiveRecord::Migration[8.0]
  def change
    add_column :dynamic_forms, :evaluate_access_with_formula, :boolean, default: false
    add_column :dynamic_forms, :access_formula, :string
  end
end
