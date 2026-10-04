# frozen_string_literal: true

class MakeDashboardFeatureDependentOfMenuFeature < ActiveRecord::Migration[6.0]
  def up
    Dynamic::Schema.find_each do |schema|
      schema.features.find_by_name('Dynamic::Menu::Feature')&.update(dependency_order: 40)
    end
  end

  def down
    Dynamic::Schema.find_each do |schema|
      schema.features.find_by_name('Dynamic::Menu::Feature')&.update(dependency_order: nil)
    end
  end
end
