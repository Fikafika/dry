class AddConditionKlassToDynamicSchemaSequences < ActiveRecord::Migration[8.0]
  def change
    change_table :dynamic_schema_sequences do |t|
      t.belongs_to :condition_klass, index: {name: 'index_dynamic_schema_sequences_condition_klass_id'}, type: :uuid
      t.integer :condition_type, default: 0
    end
  end
end
