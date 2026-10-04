# frozen_string_literal: true

class AddSchemaIdToUneekpermissionRules < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      UneekPermission::Rule.where('klass_name LIKE ?', "#{schema.const.name}::%").where(schema_id: nil).find_each do |rule|
        rule.update_column(:schema_id, schema.id)
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
