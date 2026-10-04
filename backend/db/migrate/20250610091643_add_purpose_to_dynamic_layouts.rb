class AddPurposeToDynamicLayouts < ActiveRecord::Migration[8.0]
  def change
    add_column :dynamic_layouts, :purpose, :string, if_not_exists: true
  end
end
