# frozen_string_literal: true

class AddArticleConcernToProductFeatures < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      feature = schema.features.detect {|f| f.name == 'Dynamic::Product::Feature'}
      next unless feature
      concern = feature.concerns.detect {|c| c.name == 'Article'}
      next if concern
      feature.concerns.create!(
        name: 'Article',
        human_name_fr: 'Article',
        human_name_en: 'Article',
      )
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
