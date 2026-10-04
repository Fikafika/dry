# frozen_string_literal: true

class UpdateMailHostingMessageAttributeTypesAndNames < ActiveRecord::Migration[8.0]
  TARGET_ATTRIBUTES = {
    'subject' => { type: 'String', human_name_en: 'Subject', human_name_fr: 'Sujet' },
    'imap_id' => { type: 'String', human_name_en: 'Imap', human_name_fr: 'Imap' },
    'text' => { type: 'Text', human_name_en: 'Text', human_name_fr: 'Texte' },
    'attachments' => { type: 'String', human_name_en: 'Attachments', human_name_fr: 'Pieces jointes' }
  }.freeze

  def up
    ::OpenSearch::Model.client.wait_for_server
    Dynamic::Schema.find_each do |schema|
      feature = schema.features.find_by(name: 'Dynamic::MailHosting::Feature')
      next unless feature

      message_klass = feature.options.find_by(name: 'message_klass')&.value
      next unless message_klass.is_a?(Dynamic::Schema::Klass)

      message_concern = feature.concerns.detect {|c| c.name == 'Message'}
      Dynamic::MailHosting::Feature.create_message_attributes(message_klass, message_concern)
      update_message_attribute_types_and_names!(message_klass)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def update_message_attribute_types_and_names!(message_klass)
    TARGET_ATTRIBUTES.each do |attr_name, expected|
      attribute = message_klass.attrs.find_by(name: attr_name)
      next unless attribute

      if attribute.type.to_s != expected[:type]
        message_klass.attrs.where(id: attribute.id).update_all(type: expected[:type])
        attribute = message_klass.attrs.find(attribute.id)
      end

      updates = {}
      updates[:human_name_en] = expected[:human_name_en] if attribute.human_name_en != expected[:human_name_en]
      updates[:human_name_fr] = expected[:human_name_fr] if attribute.human_name_fr != expected[:human_name_fr]
      attribute.update!(updates) if updates.any?
    end
  end
end
