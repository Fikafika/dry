require 'dynamic_record'

class AddSizeOthersToDynamicChartGroups < ActiveRecord::Migration[6.0]
  include ::Dynamic::Mount::Migration

  def change
    change_tables(::Dynamic::Chart::Group) do |t|
      t.integer :size, if_not_exists: true
      t.boolean :show_others, if_not_exists: true
    end
  end
end
