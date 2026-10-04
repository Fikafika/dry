class AddItemToDynamicDashboards < ActiveRecord::Migration[6.0]
  include ::Dynamic::Mount::Migration

  def change
    change_tables(::Dynamic::Dashboard) do |t|
      t.belongs_to :item, type: :uuid, default: nil, if_not_exists: true
    end
  end
end
