class AddHasPhotoToUsers < ActiveRecord::Migration[6.0]
  def change
    change_table :users do |t|
      t.boolean :has_photo, null: false, default: false
    end
  end
end
