class AddModeToDynamicLayouts < ActiveRecord::Migration[6.0]
  def change
    add_column :dynamic_layouts, :mode, :string
  end
end
