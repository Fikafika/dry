class CreateUneekPermissionManifests < ActiveRecord::Migration[8.0]
  def change
    create_table :uneek_permission_manifests, id: :uuid, if_not_exists: true do |t|
      t.string :name
      t.timestamps
      t.index [:name], unique: true, name: 'uneek_permission_manifests_uq'
    end
  end
end
