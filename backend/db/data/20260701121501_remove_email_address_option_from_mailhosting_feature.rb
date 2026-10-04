# frozen_string_literal: true

class RemoveEmailAddressOptionFromMailhostingFeature < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      feature = schema.features.detect {|f| f.name == 'Dynamic::MailHosting::Feature'}
      next unless feature&.enabled

      option = feature.options.detect {|o| o.name == 'email_address_attribute'}
      option&.destroy!
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
