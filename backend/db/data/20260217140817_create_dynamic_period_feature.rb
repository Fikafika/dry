# frozen_string_literal: true

class CreateDynamicPeriodFeature < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |s|
      next if s.features.where(name: 'Dynamic::Period::Feature').exists?
      s.create_feature('Dynamic::Period::Feature')
    end
  end

  def down
  end
end
