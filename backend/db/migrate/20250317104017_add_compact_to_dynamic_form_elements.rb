class AddCompactToDynamicFormElements < ActiveRecord::Migration[8.0]
  def change
    add_column :dynamic_form_elements, :compact, :boolean, default: false, if_not_exists: true
  end
end
