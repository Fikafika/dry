# frozen_string_literal: true

class AddCurrencyFeature < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      next if schema.features.detect {|f| f.name ==  'Dynamic::Currency::Feature'}
      schema.create_feature('Dynamic::Currency::Feature')
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
