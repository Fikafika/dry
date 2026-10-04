class AddPurposeToDynamicForms < ActiveRecord::Migration[8.0]
  def change
    add_column :dynamic_forms, :purpose, :string, if_not_exists: true
  end
end
