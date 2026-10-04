# frozen_string_literal: true

class RecomputeDependenciesFromFormulas < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      schema.klasses.each do |k|
        Dynamic::Formula::Feature.compute_dependencies_from_formulas(k)
      end
    end
  end

  def down
  end
end
