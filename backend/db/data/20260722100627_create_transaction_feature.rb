# frozen_string_literal: true

class CreateTransactionFeature < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      feature = schema.features.detect {|f| f.name == 'Dynamic::Transaction::Feature'}
      next if feature
      schema.features.create!(Dynamic::Transaction::Feature.feature_attributes.merge(name: 'Dynamic::Transaction::Feature'))
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
