class ReplaceClickTypeToProtocols < ActiveRecord::Migration[6.0]
  def change
    rename_column :dynamic_schema_attributes, :click_type, :protocols
  end
end
