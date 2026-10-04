# frozen_string_literal: true

class ResetMailHostingSyncStatesForSsoUuidSwitch < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      feature = schema.features.find_by(name: 'Dynamic::MailHosting::Feature')
      next unless feature

      schema.load

      sync_state_klass = "D::#{schema.name}::R::MailHosting::SyncState".safe_constantize
      next unless sync_state_klass

      sync_state_klass.update_all(
        last_sync_at: nil,
        last_message_id: nil,
        rules_signature: nil,
        cursor: nil
      )
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
