# frozen_string_literal: true

class CreateEventFeature < ActiveRecord::Migration[6.0]
  def up
    Dynamic::Schema.find_each do |s|
      next if s.features.where(name: 'Dynamic::Event::Feature').exists?
      s.create_feature('Dynamic::Event::Feature')
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
