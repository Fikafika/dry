# frozen_string_literal: true

class AddPublicRoleIndexedOptionToDynamicPermission < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      feature = schema.features.detect {|f| f.name == 'Dynamic::Permission::Feature'}
      next unless feature
      option = feature.options.detect {|o| o.name == 'public_role_indexed'}
      next if option
      feature.options.create!(
        name: 'public_role_indexed',
        type: 'Boolean',
        value: true,
        visible: false
      )
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
