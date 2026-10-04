class AddOnLoadScriptToDynamicForms < ActiveRecord::Migration[8.0]
  def change
    change_table :dynamic_forms do |t|
      t.text :on_load_script
    end
  end
end
