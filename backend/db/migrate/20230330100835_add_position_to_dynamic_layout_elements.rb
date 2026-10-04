class AddPositionToDynamicLayoutElements < ActiveRecord::Migration[6.0]
  def change
    add_column :dynamic_layout_elements, :position, :integer
  end
end
