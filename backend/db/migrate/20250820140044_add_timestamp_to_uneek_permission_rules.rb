class AddTimestampToUneekPermissionRules < ActiveRecord::Migration[8.0]
  def up
    change_table :uneek_permission_rules do |t|
      t.timestamps null: true
    end

    now = DateTime.current
    UneekPermission::Rule.update_all(created_at: now, updated_at: now)

    change_column :uneek_permission_rules, :created_at, :datetime, null: false
    change_column :uneek_permission_rules, :updated_at, :datetime, null: false
  end

  def down
    remove_column :uneek_permission_rules, :created_at
    remove_column :uneek_permission_rules, :updated_at
  end
end
