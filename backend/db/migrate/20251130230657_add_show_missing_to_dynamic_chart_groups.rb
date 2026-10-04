require 'dynamic_record'

class AddShowMissingToDynamicChartGroups < ActiveRecord::Migration[8.0]
  include ::Dynamic::Mount::Migration

  def change
    change_tables(::Dynamic::Chart::Group) do |t|
      t.boolean :show_missing, default: false
    end
  end
end
