# frozen_string_literal: true

class CreateAdminRule < ActiveRecord::Migration[6.0]
  def up
    ::OpenSearch::Model.client.wait_for_server
    ActiveRecord::Base.connection.clear_cache!
    UneekSsoClient.sync_all!
    Role.find_each do |role|
      role.__opensearch__.update_document
      role.send(:create_admin_rules) if role.admin
    end
  end

  def down
    # raise ActiveRecord::IrreversibleMigration
  end
end
