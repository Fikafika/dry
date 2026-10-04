# frozen_string_literal: true

class RecomputeAllDependenciesFromFormulas < ActiveRecord::Migration[6.0]
  def up
    Dynamic::Schema.find_each do |s|
      next unless s.features.detect{|f| f.name == 'Dynamic::Formula::Feature'}&.enabled?
      s.load
      s.klasses.find_each do |k|
        ::Dynamic::Formula::Feature.compute_dependencies_from_formulas(k)
      end
      s.touch
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
