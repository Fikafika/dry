# frozen_string_literal: true

class UpdateMailHostingWithReceiversAssociation < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      feature = schema.features.detect {|f| f.name == 'Dynamic::MailHosting::Feature'}
      next unless feature&.enabled

      message_concern = feature.concerns.detect {|c| c.name == 'Message'}
      message_klass = message_concern.klass
      unique_email_klass = Dynamic::MailHosting::Feature.unique_email_schema_klass(feature)

      assoc_names = []
      options_assocs = message_concern.options.each do |o|
        next unless o.name.end_with?('_association')
        assoc_name = o.name.gsub('_association', '')
        assoc_names << assoc_name unless assoc_name == 'sender'
      end

      receivers_assoc = message_klass.associations.create_with(
        type: 'HasMany',
        formula: assoc_names.join(' + '),
        target_klass: unique_email_klass,
        human_name_fr: 'Récepteurs',
        human_name_en: 'Receivers',
      ).find_or_create_by!(name: 'receivers')

      messages_assoc = unique_email_klass.associations.create_with(
        human_name_en: 'Messages',
        human_name_fr: 'Messages',
        type: 'HasMany',
        target_klass: message_klass,
        inverse_of: receivers_assoc
      ).find_or_create_by!(name: 'messages')

      receivers_assoc.update!(inverse_of: messages_assoc)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
