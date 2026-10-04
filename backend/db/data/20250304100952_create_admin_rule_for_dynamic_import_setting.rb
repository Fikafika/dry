# frozen_string_literal: true

class CreateAdminRuleForDynamicImportSetting < ActiveRecord::Migration[8.0]
  def up
    Community.find_each do |community|
      schema = community.schema
      admin_roles = Role.where(community_id: community.id, admin: true).all
      admin_roles.each do |role|
        admin_rule_for_import = UneekPermission::Rule.create_with(
          schema: schema,
          instance_field: 'schema_id',
          expression_method: '==',
          expression_value: schema.id,
          grant: 15,
        ).find_or_create_by!(
          receiver: role,
          klass_name: 'Dynamic::Import::Setting',
        )
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
