class AddEditorToDynamicSchemaAttributesAssociationsAndAttachments < ActiveRecord::Migration[6.0]
  def change
    change_table :dynamic_schema_attributes do |t|
      t.integer :editor, if_not_exists: true
    end
    change_table :dynamic_schema_associations do |t|
      t.integer :editor, if_not_exists: true
    end
    change_table :dynamic_schema_attachments do |t|
      t.integer :editor, if_not_exists: true
    end
  end
end
