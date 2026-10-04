class AddSchemaToUneekPermissionRules < ActiveRecord::Migration[6.0]
  def change
    add_reference :uneek_permission_rules, :schema, type: :uuid
  end
end