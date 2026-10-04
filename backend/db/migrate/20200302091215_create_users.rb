class CreateUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :users, id: :uuid do |t|
      if t.respond_to?(:uuid)
        t.uuid :uneek_sso_uuid
      else
        t.string :uneek_sso_uuid, limit: '36'
      end

      t.string :login, null: false
      t.string :email, null: false
      t.string :first_name
      t.string :last_name
      t.boolean :super_admin, null: false, default: false
      t.string :language

      t.string :uneek_sso_syncable_fingerprint
      t.string :uneek_sso_client_syncable_fingerprint

      t.timestamps
    end
    add_index :users, :uneek_sso_uuid, unique: true
    add_index :users, :login, unique: true
  end

end
