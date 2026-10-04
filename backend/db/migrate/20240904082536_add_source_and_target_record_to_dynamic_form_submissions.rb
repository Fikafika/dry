class AddSourceAndTargetRecordToDynamicFormSubmissions < ActiveRecord::Migration[6.0]
  def change
    change_table :dynamic_form_submissions do |t|
      t.belongs_to :source_record, polymorphic: true, index: {name: 'index_dynamic_form_s_on_source_record_type_and_id' }, type: :uuid
      t.belongs_to :target_record, polymorphic: true, index: {name: 'index_dynamic_form_s_on_target_record_type_and_id' }, type: :uuid
    end
  end
end
