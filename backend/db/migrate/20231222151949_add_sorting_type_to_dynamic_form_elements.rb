class AddSortingTypeToDynamicFormElements < ActiveRecord::Migration[6.0]
  def change
    change_table :dynamic_form_elements do |t|
      t.string :sorting_attribute
      t.string :sorting_type
    end
  end
end
