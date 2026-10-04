# frozen_string_literal: true

class RemoveAdminRoleDocumentsFromOpensearch < ActiveRecord::Migration[8.0]
  def up
    ::OpenSearch::Model.client.wait_for_server
    Role.where(admin: true).find_each do |role|
      begin
        role.__opensearch__.delete_document
      rescue ::OpenSearch::Transport::Transport::Errors::NotFound
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
