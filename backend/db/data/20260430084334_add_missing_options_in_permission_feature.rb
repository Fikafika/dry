# frozen_string_literal: true

class AddMissingOptionsInPermissionFeature < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      feature = schema.features.detect {|f| f.name == 'Dynamic::Permission::Feature'}
      next unless feature
      feature_klass = feature.name.safe_constantize
      next unless feature_klass
      options_attrs = feature_klass.feature_attributes[:options_attributes]
      options_attrs.each do |attrs|
        next if feature.options.detect {|o| o.name == attrs[:name]}
        feature.options.create!(attrs)
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
