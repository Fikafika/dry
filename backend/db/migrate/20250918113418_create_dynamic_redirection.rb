class CreateDynamicRedirection < ActiveRecord::Migration[8.0]
  def change
    create_table :dynamic_redirections, id: :uuid do |t|
      t.string :name, null: false
      t.belongs_to :schema, null: false, type: :uuid
      t.belongs_to :klass, type: :uuid
      t.boolean :enabled, default: true
      t.string :condition_type
      t.json :condition_params, default: {}
      t.string :target_type, null: false
      t.belongs_to :target_klass, type: :uuid
      t.text :target_formula
      t.json :target_params, default: {}
      t.string :fallback_type
      t.belongs_to :fallback_klass, type: :uuid
      t.text :fallback_formula
      t.json :fallback_params, default: {}
      t.timestamps
    end
  end
end
