class CreateUserRoles < ActiveRecord::Migration[6.0]
  def change
    create_table :user_roles, id: :uuid do |t|
      t.belongs_to :user, :null => false, :foreign_key => true, :index => false, :type => :uuid
      t.belongs_to :role, :null => false, :foreign_key => true, :index => true, :type => :uuid
      t.timestamps :null => false

      if t.respond_to?(:uuid)
        t.uuid :uneek_sso_uuid
      else
        t.string :uneek_sso_uuid, :limit => '36'
      end
      t.string :uneek_sso_syncable_fingerprint
      t.string :uneek_sso_client_syncable_fingerprint
    end
    add_index :user_roles, [:user_id, :role_id], :unique => true, :name => :user_roles_uq
  end
end
