# frozen_string_literal: true

class AddGlobalFalseToOptionsOfPeriodFeature < ActiveRecord::Migration[8.0]
  def up
    options.update_all(global: false)
  end

  def down
    options.update_all(global: true)
  end

  def options
    Dynamic::Schema::Option::Base.joins('JOIN dynamic_schema_concerns AS owner ON owner_id = owner.id').where(
      'owner.name': ['Period', 'BelongsToPeriod'],
    )
  end
end
