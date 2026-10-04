# frozen_string_literal: true

class UpdateOpensearchFls < ActiveRecord::Migration[8.0]
  def up
    ::OpenSearch::Model.client.wait_for_server
    Dynamic::Schema::Klass.find_each do |k|
      k.synchronize_index_permissions
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
