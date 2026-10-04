class AddAccessFormulaRecordToDynamicForms < ActiveRecord::Migration[8.0]
  def change
    add_belongs_to :dynamic_forms, :access_formula_record, polymorphic: true, null: true, index: {name: 'index_dynamic_forms_on_access_formula_record_id'}, type: :uuid
  end
end