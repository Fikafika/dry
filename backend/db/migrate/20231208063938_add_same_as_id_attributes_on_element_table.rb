class AddSameAsIdAttributesOnElementTable < ActiveRecord::Migration[6.0]
  def change
    change_table :dynamic_form_elements do |t|
      t.uuid :same_as_id
    end
  end
end
