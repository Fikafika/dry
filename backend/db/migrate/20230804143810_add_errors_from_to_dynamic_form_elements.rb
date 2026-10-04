class AddErrorsFromToDynamicFormElements < ActiveRecord::Migration[6.0]
  def change
    change_table :dynamic_form_elements do |t|
      t.json :errors_from
    end
  end
end
