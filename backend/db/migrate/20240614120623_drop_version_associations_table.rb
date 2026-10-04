class DropVersionAssociationsTable < ActiveRecord::Migration[6.0]
  def change
    drop_table :version_associations if table_exists?(:version_associations)
  end
end
