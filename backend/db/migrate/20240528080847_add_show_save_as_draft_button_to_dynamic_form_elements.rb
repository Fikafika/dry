class AddShowSaveAsDraftButtonToDynamicFormElements < ActiveRecord::Migration[6.0]
  def change
    change_table :dynamic_form_elements do |t|
      t.boolean :show_save_as_draft_button, default: false
    end

    change_table :dynamic_form_element_translations do |t|
      t.string :save_as_draft_button_text
    end
  end
end
