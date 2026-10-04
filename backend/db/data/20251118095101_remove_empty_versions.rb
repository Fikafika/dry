# frozen_string_literal: true

class RemoveEmptyVersions < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      schema.load
      schema.klasses.each do |k|
        vk = k.const.version_class_name.safe_constantize
        vk.where("object_changes IS NULL OR CAST(object_changes AS TEXT) = '{}'").where(event: 'update').delete_all
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
