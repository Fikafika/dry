class AddRecordTypeForDefaultValueFormulaToDynamicFormElement < ActiveRecord::Migration[6.0]
  def change
    change_table :dynamic_form_elements do |t|
      t.integer :record_type_for_default_value_formula
    end
  end
end
