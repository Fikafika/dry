class AddMenuItemIdToDynamicLayouts < ActiveRecord::Migration[8.0]
  def change
    change_table :dynamic_layouts do |t|
      t.uuid :menu_item_id
    end
  end
end
