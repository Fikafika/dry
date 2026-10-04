# frozen_string_literal: true

class CreateRecipientInfoFeature < ActiveRecord::Migration[6.0]
  def up
    Dynamic::Schema.find_each do |s|
      next if s.features.where(name: 'Dynamic::RecipientInfo::Feature').exists?
      s.create_feature('Dynamic::RecipientInfo::Feature')
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
