class AddNormalizationsTables < ActiveRecord::Migration[8.0]

  def change
    create_table :dynamic_schema_normalizations, **table_options do |t|
      t.string :name
      t.string :type, index:true
      t.json :options
      t.belongs_to :schema, null: false, index: true, type: :uuid
      t.belongs_to :klass, index: true, type: :uuid
      t.belongs_to :attr, index: true, type: :uuid
      t.timestamps
      t.datetime :deleted_at, index: true
      t.index [:schema_id, :klass_id, :attr_id], where: 'deleted_at IS NULL', name: 'index_dynamic_schema_normalizations'
    end

    create_table :dynamic_schema_normalization_translations, **table_options do |t|
      t.belongs_to :schema, null: false, index: true, type: :uuid
      t.references :dynamic_schema_normalization, index: {name: 'index_dynamic_schema_normalization_translations_attribute_id'}, type: :uuid
      t.string :human_name
      t.string :locale
      t.timestamps
      t.datetime :deleted_at, index: true
    end
  end

  def table_options
    {id: :uuid, if_not_exists: true}
  end

end