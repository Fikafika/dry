# frozen_string_literal: true

class UpdateMailHostingFeatureOptions < ActiveRecord::Migration[8.0]

  ATTR_MAPPING = {
    subject: {
      human_name_fr: 'Attribut du sujet',
      human_name_en: 'Subject attribute',
      type: 'String',
      coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
      value: nil,
      global: false,
    },
    imap_id: {
      human_name_fr: "Attribut de l'id IMAP",
      human_name_en: 'IMAP id attribute',
      type: 'String',
      coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
      value: nil,
      global: false,
    },
    text: {
      human_name_fr: 'Attribut du contenu',
      human_name_en: 'Content attribute',
      type: 'String',
      coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
      value: nil,
      global: false,
    },
    attachments: {
      human_name_fr: 'Attribut de pièces jointes',
      human_name_en: 'Attachments attribute',
      type: 'String',
      coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
      value: nil,
      global: false,
    }
  }

  ASSOC_MAPPING = {
    sender: {
      name: 'sender_association',
      human_name_fr: "Association de l'émetteur",
      human_name_en: 'Sender association',
      type: 'String',
      coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
      value: nil,
      global: false,
    },
    recipients: {
      name: 'recipients_association',
      human_name_fr: 'Association des destinataire',
      human_name_en: 'Recipients association',
      type: 'String',
      coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
      value: nil,
      global: false,
    },
    cc: {
      name: 'carbon_copy_association',
      human_name_fr: 'Association des copies carbones',
      human_name_en: 'Carbon copy association',
      type: 'String',
      coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
      value: nil,
      global: false,
    },
    bcc: {
      name: 'blind_carbon_copy_association',
      human_name_fr: 'Association des copies carbones invisible',
      human_name_en: 'Blind carbon copy association',
      type: 'String',
      coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
      value: nil,
      global: false,
    },
  }

  def up
    Dynamic::Schema.find_each do |schema|
      feature = schema.features.detect {|f| f.name == 'Dynamic::MailHosting::Feature'}
      next unless feature

      sync_options_to_destroy =  ['messages_last_sync_at', 'messages_last_message_id', 'messages_rules_signature']
      feature.options.select {|o| o.name.in?(sync_options_to_destroy)}.each(&:destroy!)
      next unless feature.enabled

      message_concerns = feature.concerns.select {|c| c.name == 'Message'}
      message_concerns.each do |c|
        attr_option = c.options.detect {|o| o.name == 'attr_mapping'}
        attr_option.value.each do |k, v|
          k_ = k.to_sym
          attrs = ATTR_MAPPING[k_]
          attr = c.klass.attrs.detect {|a| a.name == v}
          c.options.create!(attrs.merge(name: "#{k}_attribute", value: attr))
        end
        attr_option.destroy!

        assoc_option = c.options.detect {|o| o.name == 'association_mapping'}
        assoc_option.value.each do |k, v|
          k_ = k.to_sym
          attrs = ASSOC_MAPPING[k_]
          assoc = c.klass.associations.detect {|a| a.name == v}
          c.options.create!(attrs.merge(value: assoc))
        end
        assoc_option.destroy!
      end

      feature.concern_templates.detect {|c| c.name == 'Message'}&.destroy!
      feature.options.detect {|o| o.name == 'message_klass'}&.destroy!

      communication_feature = schema.features.detect {|f| f.name == 'Dynamic::Communication::Feature'}
      email_klass = communication_feature.concerns.detect {|c| c.name == 'Email'}&.klass
      unless email_klass
        Rails.logger.error { "Could not find Email klass for #{schema.name}"}
        next
      end
      email_concern = feature.concerns.detect {|c| c.name == 'Email'}

      attr_option = email_concern.options.detect {|o| o.name == 'attr_mapping'}
      attr = email_klass.attrs.detect {|a| a.name == attr_option.value['email_address']}
      feature.options.create!(
        name: 'email_address_attribute',
        human_name_en: 'Attribut adresse de la table Email',
        human_name_fr: 'Address attribute from email table',
        type: 'String',
        coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
        value: attr
      )

      feature.concerns.where(name: 'Email').destroy_all
      feature.concern_templates.detect {|c| c.name == 'Email'}&.destroy!
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
