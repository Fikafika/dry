# frozen_string_literal: true

class CleanupMailHostingSyncTrackingOptions < ActiveRecord::Migration[8.0]
  LEGACY_SYNC_OPTION_NAMES = [
    'messages_last_sync_at',
    'messages_last_message_id',
    'messages_rules_signature',
  ].freeze

  def up
    Dynamic::Schema.find_each do |schema|
      feature = schema.features.find_by(name: 'Dynamic::MailHosting::Feature')
      next unless feature

      schema.load

      sync_state_klass = "D::#{schema.name}::R::MailHosting::SyncState".safe_constantize
      next unless sync_state_klass

      sync_state = sync_state_klass.first_or_create!
      attrs = {}

      if sync_state.last_sync_at.blank?
        raw_last_sync_at = feature.options.find_by(name: 'messages_last_sync_at')&.value
        parsed_last_sync_at = Time.zone.parse(raw_last_sync_at.to_s) rescue nil
        attrs[:last_sync_at] = parsed_last_sync_at if parsed_last_sync_at
      end

      if sync_state.last_message_id.blank?
        raw_last_message_id = feature.options.find_by(name: 'messages_last_message_id')&.value
        attrs[:last_message_id] = raw_last_message_id if raw_last_message_id.present?
      end

      if sync_state.rules_signature.blank?
        raw_rules_signature = feature.options.find_by(name: 'messages_rules_signature')&.value
        attrs[:rules_signature] = raw_rules_signature if raw_rules_signature.present?
      end

      sync_state.update!(attrs) if attrs.any?
      feature.options.where(name: LEGACY_SYNC_OPTION_NAMES).destroy_all
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
