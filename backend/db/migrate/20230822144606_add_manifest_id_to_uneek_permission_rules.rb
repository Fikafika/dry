class AddManifestIdToUneekPermissionRules < ActiveRecord::Migration[8.0]
  def change
    add_reference :uneek_permission_rules, :manifest, index: true, type: :uuid, if_not_exists: true
  end
end
