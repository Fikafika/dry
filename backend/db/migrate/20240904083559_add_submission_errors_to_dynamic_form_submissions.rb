class AddSubmissionErrorsToDynamicFormSubmissions < ActiveRecord::Migration[6.0]
  def change
    change_table :dynamic_form_submissions do |t|
      t.text :submission_errors
    end
  end
end
