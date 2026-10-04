class CreateUneekPermissionPredefinedReceivers < ActiveRecord::Migration[6.0]
  def change
    create_table :uneek_permission_predefined_receivers, id: :uuid do |t|
      t.string :name
      t.string :type
      t.index [:type], unique: true, name: :uneek_predefined_receiver_uq
    end
  end
end
