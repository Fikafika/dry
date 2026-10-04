class AddFormulaToDynamicSchemaAttachments < ActiveRecord::Migration[8.0]
  def change
    add_column :dynamic_schema_attachments, :formula, :string, if_not_exists: true
  end
end
