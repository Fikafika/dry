class AddSortOrderToDynamicChartBases < ActiveRecord::Migration[8.0]
  include ::Dynamic::Mount::Migration

  def change
    change_tables(::Dynamic::Chart::Base) do |t|
      t.json :sort_order
    end
  end
end