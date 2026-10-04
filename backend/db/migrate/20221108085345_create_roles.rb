class CreateRoles < ActiveRecord::Migration[6.0]
  def up
    create_table :roles, id: :uuid do |t|
      t.string :name, :null => false
      t.belongs_to :community, :null => false, :foreign_key => true, :index => false, :type => :uuid
      t.boolean :default, :null => false, :default => false
      t.timestamps :null => false

      if t.respond_to?(:uuid)
        t.uuid :uneek_sso_uuid
      else
        t.string :uneek_sso_uuid, :limit => '36'
      end
      t.string :uneek_sso_syncable_fingerprint
      t.string :uneek_sso_client_syncable_fingerprint

      t.boolean :admin, :null => false, :default => false

    end
    add_index :roles, [:community_id, :name], :unique => true

    ::Role.create_translation_table!
  end

  def down
    ::Role.drop_translation_table!

    drop_table :roles
  end
end
