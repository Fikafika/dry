class AddSizeLimitToDynamicSchemaAttachments < ActiveRecord::Migration[8.0]
  def change
    add_column :dynamic_schema_attachments, :size_limit, :float, if_not_exists: true
  end
end
