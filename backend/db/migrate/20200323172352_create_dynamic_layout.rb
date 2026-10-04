class CreateDynamicLayout < ActiveRecord::Migration[6.0]

  def change
    create_table :dynamic_layouts, id: :uuid do |t|
      t.belongs_to :schema, null: false, index: true, type: :uuid
      t.string :klass_name

      t.string :name
      t.integer :actions

      t.timestamps
      t.datetime :deleted_at, index: true
    end

    create_table :dynamic_layout_translations, id: :uuid  do |t|
      t.belongs_to :schema, null: false, index: true, type: :uuid
      t.references :dynamic_layout, index: {name: 'index_dynamic_layout_translations_id'}, type: :uuid
      t.string :human_name
      t.string :locale
    end

    create_table :dynamic_layout_elements, id: :uuid do |t|
      t.string :component
      t.json :component_params, default: {}
      t.string :component_params_converter_type
      t.json :component_params_converter_options, default: {}

      t.belongs_to :schema, null: false, index: true, type: :uuid
      t.belongs_to :layout, null: false, index: true, type: :uuid

      t.belongs_to :parent, index: true, type: :uuid

      t.timestamps
      t.datetime :deleted_at, index: true
    end

  end
end
