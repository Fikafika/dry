# frozen_string_literal: true

class CreateMergeFeature < ActiveRecord::Migration[6.0]
  def up
    Dynamic::Schema.find_each do |s|
      next if s.features.where(name: 'Dynamic::Merge::Feature').exists?
      s.create_feature('Dynamic::Merge::Feature')
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
