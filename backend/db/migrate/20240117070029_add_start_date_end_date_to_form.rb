class AddStartDateEndDateToForm < ActiveRecord::Migration[6.0]
  def change
    add_column :dynamic_forms, :start_date, :datetime
    add_column :dynamic_forms, :end_date, :datetime
  end
end
