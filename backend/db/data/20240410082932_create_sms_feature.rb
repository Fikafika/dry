# frozen_string_literal: true

class CreateSmsFeature < ActiveRecord::Migration[6.0]
  def up
    Dynamic::Schema.find_each do |s|
      next if s.features.where(name: 'Dynamic::Sms::Feature').exists?
      s.create_feature('Dynamic::Sms::Feature')
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
