class CreateTools < ActiveRecord::Migration[6.0]
  def change
    create_table :tools, id: :uuid do |t|
      t.references :community, :foreign_key => true, :index => false, :null => false, :type => :uuid
      t.string :name, :null => false
      t.string :application_name, :null => false
      t.string :uri, :null => false

      if t.respond_to?(:uuid)
        t.uuid :uneek_sso_uuid
      else
        t.string :uneek_sso_uuid, :limit => '36'
      end
      t.string :uneek_sso_syncable_fingerprint
      t.string :uneek_sso_client_syncable_fingerprint

      t.timestamps :null => false
    end
    add_index :tools, [:community_id, :name], :unique => true
    add_index :tools, :uneek_sso_uuid, :unique => true
  end
end
