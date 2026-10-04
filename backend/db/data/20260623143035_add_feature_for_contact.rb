# frozen_string_literal: true

class AddFeatureForContact < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      schema.create_feature('Dynamic::Contact::Feature') unless schema.features.detect {|f| f.name == 'Dynamic::Contact::Feature'}
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
