class CreateUserTools < ActiveRecord::Migration[6.0]
  def change
    create_table :user_tools, id: :uuid do |t|
      t.references :user, :foreign_key => true, :index => false, :null => false, :type => :uuid
      t.references :tool, :foreign_key => true, :index => true, :null => false, :type => :uuid

      t.timestamps :null => false
    end
    add_index :user_tools, [:user_id, :tool_id], :unique => true
  end
end
