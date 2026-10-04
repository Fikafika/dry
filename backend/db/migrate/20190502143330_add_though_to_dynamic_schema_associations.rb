class AddThoughToDynamicSchemaAssociations < ActiveRecord::Migration[8.0]
  def change
    add_reference :dynamic_schema_associations, :through, type: :uuid, if_not_exists: true
  end
end
