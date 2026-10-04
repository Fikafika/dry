# frozen_string_literal: true

class AddAttributesToOpensearchUsers < ActiveRecord::Migration[8.0]
  def up
    ::OpenSearch::Model.client.wait_for_server
    User.where(super_admin: false).find_each do |u|
      u.put_os_user
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
