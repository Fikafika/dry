# frozen_string_literal: true

class CreateAmountFeature < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      feature = schema.features.detect {|f| f.name == 'Dynamic::Amount::Feature'}
      next if feature
      schema.features.create!(Dynamic::Amount::Feature.feature_attributes.merge(name: 'Dynamic::Amount::Feature'))
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
