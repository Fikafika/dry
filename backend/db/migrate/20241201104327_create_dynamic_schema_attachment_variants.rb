class CreateDynamicSchemaAttachmentVariants < ActiveRecord::Migration[8.0]
  def change
    create_table :dynamic_schema_attachment_variants, if_not_exists: true, id: :uuid do |t|
      t.string :name, null: false
      t.integer :format
      t.integer :quality
      t.integer :resize_type
      t.integer :resize_width
      t.integer :resize_height
      t.boolean :crop, default: false
      t.integer :crop_left
      t.integer :crop_top
      t.integer :crop_width
      t.integer :crop_height
      t.text :comment
      t.belongs_to :schema, null: false, index: true, type: :uuid
      t.belongs_to :attachment, index: true, type: :uuid
      t.string :type, index: true
      t.timestamps
      t.datetime :deleted_at, index: true
      t.index [:schema_id, :attachment_id, :name], where: 'deleted_at IS NULL', unique: true, name: 'uniq_index_dynamic_schema_attachment_variants'
    end
  end
end
