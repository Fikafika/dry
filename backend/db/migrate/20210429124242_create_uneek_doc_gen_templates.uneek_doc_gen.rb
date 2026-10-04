class CreateUneekDocGenTemplates < ActiveRecord::Migration[6.0]
  def change
    create_table :uneek_doc_gen_templates, id: :uuid do |t|
      t.string     :type,             null: false
      t.string     :name,             null: false
      t.timestamps                    null: false
      t.string     :version,          null: false
      t.string     :class_name,       null: false
      t.boolean    :multiple,         null: false, default: false
      t.references :wrapped_template, foreign_key: { to_table: :uneek_doc_gen_templates }, type: :uuid
      t.string     :wrapped_format
      t.string     :default_attachment
      t.string     :output_name_formula

      t.index :type
      t.index :class_name
    end
  end
end
