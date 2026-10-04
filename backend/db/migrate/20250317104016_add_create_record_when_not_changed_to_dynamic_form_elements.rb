class AddCreateRecordWhenNotChangedToDynamicFormElements < ActiveRecord::Migration[8.0]
  def change
    change_table :dynamic_form_elements do |t|
      t.boolean :create_record_when_not_changed, default: false
    end
  end
end
