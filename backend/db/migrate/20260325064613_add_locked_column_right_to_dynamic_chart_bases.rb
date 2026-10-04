class AddLockedColumnRightToDynamicChartBases < ActiveRecord::Migration[8.0]
  include ::Dynamic::Mount::Migration

  def change
    change_tables(::Dynamic::Chart::Base) do |t|
      t.string :locked_column_right
    end
  end
end