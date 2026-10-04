class AddHasLogoToCommunities < ActiveRecord::Migration[6.0]
  def change
    change_table :communities do |t|
      t.boolean :has_logo, null: false, default: false
    end
  end
end
