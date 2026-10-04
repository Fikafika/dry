class AddRotationToDynamicChartBases < ActiveRecord::Migration[8.0]
  include ::Dynamic::Mount::Migration

  def change
    change_tables(::Dynamic::Chart::Base) do |t|
      t.float :rotation_degree_x
      t.float :rotation_degree_y
    end
  end
end