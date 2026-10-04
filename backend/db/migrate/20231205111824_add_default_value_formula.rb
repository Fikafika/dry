class AddDefaultValueFormula < ActiveRecord::Migration[5.0]

  def change
    add_column :dynamic_form_elements, :default_value_formula, :text
  end

end
