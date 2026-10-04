class AddTextBeforeStartDateTextAfterEndDateToDynamicFormTransaltion < ActiveRecord::Migration[6.0]
  def change
    add_column :dynamic_form_translations, :text_before_start_date, :text
    add_column :dynamic_form_translations, :text_after_end_date, :text
  end
end
