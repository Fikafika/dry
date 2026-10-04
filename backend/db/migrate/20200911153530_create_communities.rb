class CreateCommunities < ActiveRecord::Migration[6.0]
  def change
    create_table :communities, id: :uuid do |t|
      t.string :name, :null => false
      t.string :permalink, :null => false
      t.references :parent, :foreign_key => { :to_table => :communities }, :index => false, type: :uuid
      t.string :short_description
      t.text :description

      if t.respond_to?(:uuid)
        t.uuid :uneek_sso_uuid
      else
        t.string :uneek_sso_uuid, :limit => '36'
      end
      t.string :uneek_sso_syncable_fingerprint
      t.string :uneek_sso_client_syncable_fingerprint

      t.timestamps
    end
    add_index :communities, :permalink, :unique => true
    add_index :communities, :parent_id
    add_index :communities, :uneek_sso_uuid, :unique => true
  end
end
