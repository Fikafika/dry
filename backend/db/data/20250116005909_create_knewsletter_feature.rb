# frozen_string_literal: true

class CreateKnewsletterFeature < ActiveRecord::Migration[6.0]
  def up
    Dynamic::Schema.find_each do |s|
      next if s.features.where(name: 'Dynamic::Knewsletter::Feature').exists?
      s.create_feature('Dynamic::Knewsletter::Feature')
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
