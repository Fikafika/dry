class RemoveSortOrderFromDynamicChartBases < ActiveRecord::Migration[8.0]
  include ::Dynamic::Mount::Migration

  def change
    change_tables(::Dynamic::Chart::Base) do |t|
      t.remove :sort_order, type: :json
    end
  end
end
