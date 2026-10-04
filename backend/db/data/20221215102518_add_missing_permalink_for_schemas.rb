# frozen_string_literal: true

class AddMissingPermalinkForSchemas < ActiveRecord::Migration[6.0]
  def up
    Dynamic::Schema.with_deleted.find_each do |schema|
      permalink = schema.class.with_deleted.where(id: schema.id).pluck(:permalink).first
      next if permalink.present?
      schema.class.connection.execute("UPDATE dynamic_schemas SET permalink = '#{'destroyed-' if schema.deleted_at}#{schema.name.underscore.gsub('_', '-')}' WHERE id = '#{schema.id}'")
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
