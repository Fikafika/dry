class AddAsyncSubmissionToDynamicForms < ActiveRecord::Migration[6.0]
  def change
    change_table :dynamic_forms do |t|
      t.boolean :async_submission, default: false
    end
  end
end
