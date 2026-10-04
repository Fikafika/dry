class AddMinMaxToDynamicFormElements < ActiveRecord::Migration[6.0]
  def change
    change_table :dynamic_form_elements do |t|
      t.integer :min
      t.integer :max
    end    
  end
end
