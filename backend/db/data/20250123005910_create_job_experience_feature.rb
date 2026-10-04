# frozen_string_literal: true

class CreateJobExperienceFeature < ActiveRecord::Migration[6.0]
  def up
    Dynamic::Schema.find_each do |s|
      next if s.features.where(name: 'Dynamic::JobExperience::Feature').exists?
      s.create_feature('Dynamic::JobExperience::Feature')
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
