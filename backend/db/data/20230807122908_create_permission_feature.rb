# frozen_string_literal: true

class CreatePermissionFeature < ActiveRecord::Migration[6.0]
  def up
    Dynamic::Schema.all.each do |schema|
      next if schema.features.where(name: 'Dynamic::Permission::Feature').exists?
      schema.create_feature('Dynamic::Permission::Feature')
    end
  end

  def down
    # raise ActiveRecord::IrreversibleMigration
  end
end
