# frozen_string_literal: true

class CreateMenuPermissions < ActiveRecord::Migration[8.0]
  def up
    ::OpenSearch::Model.client.wait_for_server
    Role.where.not(admin: true).find_each do |r|
      r.send(:create_menu_permissions)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
