class CreateDynamicThemes < ActiveRecord::Migration[6.0]
  def change
    create_table :dynamic_themes, id: :uuid do |t|
      t.string :name, null: false
      t.belongs_to :schema, null: false, index: true, type: :uuid
      t.timestamps
      t.datetime :deleted_at, index: true
      t.index [:schema_id, :name], where: 'deleted_at IS NULL', unique: true, name: 'uniq_index_dynamic_themes'
    end

    create_table :dynamic_theme_translations, id: :uuid do |t|
      t.belongs_to :schema, null: false, index: {name: 'index_dynamic_theme_tr_schema_id'}, type: :uuid
      t.references :dynamic_theme, index: {name: 'index_dynamic_theme_tr_theme_id'}, type: :uuid
      t.string :human_name
      t.string :locale
    end
  end
end
