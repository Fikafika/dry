class AddDynamicFormDefaultValueAssociations < ActiveRecord::Migration[6.0]
  def change
    create_table :dynamic_form_default_value_associations do |t|
      t.belongs_to :schema, null: false, index: true, type: :uuid
      t.belongs_to :form, null: false, index: true, type: :uuid
      t.belongs_to :element, null: false, index: true, type: :uuid
      t.belongs_to :record, polymorphic: true, index: {name: 'index_dynamic_form_dva_record_type_and_id' }, type: :uuid
      t.timestamps
      t.datetime :deleted_at, index: true
    end
  end
end
