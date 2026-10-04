# frozen_string_literal: true

class UpdatePermissionRulesHavingAssociationAsAttr < ActiveRecord::Migration[8.0]
  def up
    UneekPermission::Rule.where('klass_name LIKE ?', 'D::%').where.not(attr: nil).find_each do |r|
      assoc = Dynamic::Schema::Association::Base.find_by(schema_id: r.schema_id, name: r.attr)
      next unless assoc
      new_attr = if assoc.is_a?(Dynamic::Schema::Association::HasMany)
        assoc.name.underscore.singularize + '_ids'
      else
        assoc.name.underscore + '_id'
      end
      r.update!(attr: new_attr)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
