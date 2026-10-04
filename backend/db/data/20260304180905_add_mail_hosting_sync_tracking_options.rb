# frozen_string_literal: true

class AddMailHostingSyncTrackingOptions < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      feature = schema.features.find_by(name: 'Dynamic::MailHosting::Feature')
      next unless feature

      feature.options.create_with(
        human_name_en: 'Messages last sync at',
        human_name_fr: 'Dernière synchronisation des messages',
        type: 'String',
        value: nil,
      ).find_or_create_by!(name: 'messages_last_sync_at')

      feature.options.create_with(
        human_name_en: 'Last synchronized message id',
        human_name_fr: 'Identifiant du dernier message synchronisé',
        type: 'String',
        value: nil,
      ).find_or_create_by!(name: 'messages_last_message_id')

      feature.options.create_with(
        human_name_en: 'Messages rules signature',
        human_name_fr: 'Signature des règles de messages',
        type: 'String',
        value: nil,
      ).find_or_create_by!(name: 'messages_rules_signature')
    end
  end

  def down
    Dynamic::Schema.find_each do |schema|
      feature = schema.features.find_by(name: 'Dynamic::MailHosting::Feature')
      next unless feature

      feature.options.where(name: [
        'messages_last_sync_at',
        'messages_last_message_id',
        'messages_rules_signature',
      ]).destroy_all
    end
  end
end
