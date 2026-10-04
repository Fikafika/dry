class AddDefaultToDynamicLayouts < ActiveRecord::Migration[6.0]
  def change
    add_column :dynamic_layouts, :default, :boolean, default: false
    add_column :dynamic_layouts, :updated_when_schema_is_changed, :boolean, default: false
  end
end
