# frozen_string_literal: true

class RemoveConsentFeature < ActiveRecord::Migration[6.0]
  def up
    Dynamic::Schema.find_each do |s|
      next unless s.features.where(name: 'Dynamic::Consent::Feature').exists?
      s.features.where(name: 'Dynamic::Consent::Feature').each do |f|
        f.destroy
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
