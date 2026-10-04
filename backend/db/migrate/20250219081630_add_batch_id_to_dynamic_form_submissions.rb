class AddBatchIdToDynamicFormSubmissions < ActiveRecord::Migration[6.0]
  def change
    change_table :dynamic_form_submissions do |t|
      t.string :batch_id, index: true
    end
  end
end
