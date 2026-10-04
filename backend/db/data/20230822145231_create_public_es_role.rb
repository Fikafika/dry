# frozen_string_literal: true

class CreatePublicEsRole < ActiveRecord::Migration[6.0]
  def up
    ::OpenSearch::Model.client.wait_for_server
    UneekPermission::PredefinedReceiver::Public.instance.put_os_role_and_user
    UneekPermission::PredefinedReceiver::Public.instance.__opensearch__.index_document
    User.find_each do |user|
      user.put_os_user
    end
  end

  def down
    # raise ActiveRecord::IrreversibleMigration
  end
end
