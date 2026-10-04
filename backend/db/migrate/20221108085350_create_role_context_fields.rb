class CreateRoleContextFields < ActiveRecord::Migration[6.0]
  def up
    create_table :role_context_fields, id: :uuid do |t|
      t.belongs_to :role, :null => false, :foreign_key => true, :index => false, :type => :uuid
      t.string :name, :null => false
      t.timestamps :null => false

      if t.respond_to?(:uuid)
        t.uuid :uneek_sso_uuid
      else
        t.string :uneek_sso_uuid, :limit => '36'
      end
      t.string :uneek_sso_syncable_fingerprint
      t.string :uneek_sso_client_syncable_fingerprint
    end
    add_index :role_context_fields, [:role_id, :name], :unique => true

    ::RoleContextField.create_translation_table!
  end

  def down
    ::RoleContextField.drop_translation_table!

    drop_table :role_context_fields
  end
end
