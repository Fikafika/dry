# frozen_string_literal: true

class CreateOsRoles < ActiveRecord::Migration[8.0]
  def up
    ::OpenSearch::Model.client.wait_for_server
    Role.where(admin: false).find_each do |role|
      role.put_os_role
    end
  end

  def down
    # raise ActiveRecord::IrreversibleMigration
  end
end
