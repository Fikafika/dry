# frozen_string_literal: true

class CreateCopyFeature < ActiveRecord::Migration[6.0]
  def up
    Dynamic::Schema.find_each do |s|
      next if s.features.where(name: 'Dynamic::Copy::Feature').exists?
      s.create_feature('Dynamic::Copy::Feature')
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
