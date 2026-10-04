class CreateMemberships < ActiveRecord::Migration[6.0]
  def change
    create_table :memberships, id: :uuid do |t|
      t.references :community, :foreign_key => true, :index => false, :null => false, type: :uuid
      t.references :user, :foreign_key => true, :index => false, :null => false, type: :uuid
      t.integer :status, :null => false, :default => 0
      t.boolean :admin, :null => false, :default => false

      if t.respond_to?(:uuid)
        t.uuid :uneek_sso_uuid
      else
        t.string :uneek_sso_uuid, :limit => '36'
      end
      t.string :uneek_sso_syncable_fingerprint
      t.string :uneek_sso_client_syncable_fingerprint

      t.timestamps
    end
    add_index :memberships, [:community_id, :user_id], :unique => true
    add_index :memberships, :user_id
    add_index :memberships, :uneek_sso_uuid, :unique => true
  end
end
