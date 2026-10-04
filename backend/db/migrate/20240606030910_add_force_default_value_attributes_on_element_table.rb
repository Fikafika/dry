class AddForceDefaultValueAttributesOnElementTable < ActiveRecord::Migration[6.0]
  def change
    change_table :dynamic_form_elements do |t|
      t.boolean :force_default_value, default: false
    end
  end
end
