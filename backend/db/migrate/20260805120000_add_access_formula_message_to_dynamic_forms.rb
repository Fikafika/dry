class AddAccessFormulaMessageToDynamicForms < ActiveRecord::Migration[8.0]
  def change
    add_column :dynamic_forms, :access_formula_message, :string, if_not_exists: true
  end
end
