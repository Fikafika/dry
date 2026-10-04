class CreateUneekDocGenMergeFiles < ActiveRecord::Migration[6.0]
  def change
    create_table :uneek_doc_gen_merge_files, id: :uuid do |t|
      t.string     :type,     null: false
      t.references :template, null: false, foreign_key: { to_table: :uneek_doc_gen_templates }, index: false, type: :uuid
      t.timestamps
      t.integer    :position, null: false
      t.references :object_template, foreign_key: { to_table: :uneek_doc_gen_templates }, index: false, type: :uuid
      t.string     :attribute_name

      t.index :type
      t.index [:template_id, :position], unique: true
      t.index [:template_id, :object_template_id], name: 'index_uneek_doc_gen_files_object_template_id_uq', unique: true
      t.index :object_template_id
    end
  end
end
