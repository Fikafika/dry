class FixDynamicFormDefaultValueAssociationsPrimaryKey < ActiveRecord::Migration[8.0]
  def change
    rename_table :dynamic_form_default_value_associations, :dynamic_form_default_value_associations_sav

    rename_index :dynamic_form_default_value_associations_sav, 'index_dynamic_form_dva_record_type_and_id', 'index_dynamic_form_dvas_record_type_and_id'

    create_table :dynamic_form_default_value_associations, id: :uuid do |t|
      t.belongs_to :schema, null: false, index: true, type: :uuid
      t.belongs_to :form, null: false, index: true, type: :uuid
      t.belongs_to :element, null: false, index: true, type: :uuid
      t.belongs_to :record, polymorphic: true, index: {name: 'index_dynamic_form_dva_record_type_and_id' }, type: :uuid
      t.timestamps
      t.datetime :deleted_at, index: true
    end

    ActiveRecord::Base.connection.execute('INSERT INTO dynamic_form_default_value_associations SELECT uuid_generate_v7(), schema_id, form_id, element_id, record_type, record_id, created_at, updated_at deleted_at FROM dynamic_form_default_value_associations_sav')

    drop_table :dynamic_form_default_value_associations_sav
  end
end
