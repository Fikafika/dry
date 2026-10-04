# frozen_string_literal: true

class UpdateUserOpensearchDocuments < ActiveRecord::Migration[8.0]
  def up
    ::OpenSearch::Model.client.wait_for_server
    User.find_in_batches(batch_size: 100) do |b|
      OpenSearch::Model.bulk(b, remove_deleted: true)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
