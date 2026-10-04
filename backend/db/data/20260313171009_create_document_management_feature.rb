# frozen_string_literal: true

class CreateDocumentManagementFeature < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |s|
      next if s.features.where(name: 'Dynamic::DocumentManagement::Feature').exists?
      s.create_feature('Dynamic::DocumentManagement::Feature')
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
