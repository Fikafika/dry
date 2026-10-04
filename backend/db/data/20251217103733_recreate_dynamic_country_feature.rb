# frozen_string_literal: true

class RecreateDynamicCountryFeature < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      feature = schema.features.detect {|f| f.name == 'Dynamic::Country::Feature'}
      feature.destroy! if feature
      schema.create_feature('Dynamic::Country::Feature')
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
