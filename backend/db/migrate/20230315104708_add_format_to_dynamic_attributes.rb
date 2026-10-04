class AddFormatToDynamicAttributes < ActiveRecord::Migration[6.0]
  def change
    change_table :dynamic_schema_attributes do |t|
      t.integer :format
    end
  end
end
