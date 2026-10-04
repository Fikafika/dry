class CreateUserRoleDomainContexts < ActiveRecord::Migration[6.0]
  def change
    create_table :user_role_domain_contexts, id: :uuid do |t|
      t.belongs_to :user_role, :null => false, :foreign_key => true, :index => false, :type => :uuid
      t.string :field_name, :null => false
      t.text :value, :null => false, :array => true, :default => []
      t.timestamps :null => false

      if t.respond_to?(:uuid)
        t.uuid :uneek_sso_uuid
      else
        t.string :uneek_sso_uuid, :limit => '36'
      end
      t.string :uneek_sso_syncable_fingerprint
      t.string :uneek_sso_client_syncable_fingerprint
    end
    add_index :user_role_domain_contexts, [:user_role_id, :field_name], :unique => true
  end
end
