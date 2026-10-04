class AddValuesLimitToDynamicFormElements < ActiveRecord::Migration[6.0]
  def change
    change_table :dynamic_form_elements do |t|
      t.integer :values_limit
    end
  end
end
