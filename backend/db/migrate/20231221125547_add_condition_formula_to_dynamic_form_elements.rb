class AddConditionFormulaToDynamicFormElements < ActiveRecord::Migration[6.0]
  def change
    change_table :dynamic_form_elements do |t|
      t.json :condition_formula
    end
  end
end
