# frozen_string_literal: true

class ChangeGlobalToNumOptionsOfDynamicPeriodFeature < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema::Option::Base.where(name: ['week_num', 'month_num', 'quarter_num', 'half_year_num', 'year_num']).update_all(global: true)
  end

  def down
    Dynamic::Schema::Option::Base.where(name: ['week_num', 'month_num', 'quarter_num', 'half_year_num', 'year_num']).update_all(global: false)
  end
end
