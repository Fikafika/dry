class AddDefaultToDynamicForms < ActiveRecord::Migration[6.0]
  def change
    add_column :dynamic_forms, :default, :boolean, default: false
    add_column :dynamic_forms, :updated_when_schema_is_changed, :boolean, default: false
  end
end
