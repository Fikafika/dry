# frozen_string_literal: true

class CreateRecipientAssociationOptionsForRecipientInfoFeatures < ActiveRecord::Migration[8.0]

  def up
    Dynamic::Schema.find_each do |schema|
      feature = schema.features.detect {|f| f.name == 'Dynamic::RecipientInfo::Feature'}
      next unless feature&.enabled

      concern = feature.concerns.detect {|c| c.name == 'EmailAddress'}
      email_klass = concern.klass
      recipient_assoc = email_klass&.associations&.detect {|a| a.name == 'recipient'}

      concern.options.create_with(
        human_name_fr: "Association vers l'email unique",
        human_name_en: 'Unique email association',
        type: 'String',
        coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
        value: recipient_assoc,
      ).find_or_create_by!(name: 'recipient_association')

      concern = feature.concerns.detect {|c| c.name == 'PhoneNumber'}
      phone_klass = concern.klass
      recipient_assoc = phone_klass&.associations&.detect {|a| a.name == 'recipient'}

      concern.options.create_with(
        human_name_fr: 'Association vers le téléphone unique',
        human_name_en: 'Unique phone association',
        type: 'String',
        coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
        value: recipient_assoc,
      ).find_or_create_by!(name: 'recipient_association')
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
