class AddBaseklassIdToDynamicAssociationsAndAttachments < ActiveRecord::Migration[8.0]
  def change
    change_table :dynamic_schema_associations do |t|
      unless t.column_exists?(:baseklass_id)
        t.belongs_to :baseklass, index: true, type: :uuid
      end
    end
    change_table :dynamic_schema_attachments do |t|
      unless t.column_exists?(:baseklass_id)
        t.belongs_to :baseklass, index: true, type: :uuid
      end
    end
  end
end
