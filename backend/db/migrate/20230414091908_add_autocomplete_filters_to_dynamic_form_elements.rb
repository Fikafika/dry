class AddAutocompleteFiltersToDynamicFormElements < ActiveRecord::Migration[6.0]
  def change
    change_table :dynamic_form_elements do |t|
      t.json :autocomplete_filters
    end
  end
end
