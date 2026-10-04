class AddSessionsTable < ActiveRecord::Migration[6.0]
  def change
    create_table :sessions, if_not_exists: true do |t|
      t.string :session_id, :null => false
      t.text :data
      t.timestamps
    end
    begin # TODO move in create_table when migrate to rails 6.1
      add_index :sessions, :session_id, :unique => true
      add_index :sessions, :updated_at
    rescue
    end
  end
end
