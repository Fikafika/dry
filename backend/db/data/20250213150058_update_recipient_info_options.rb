# frozen_string_literal: true

class UpdateRecipientInfoOptions < ActiveRecord::Migration[6.0]
  def up
    Dynamic::Schema.find_each do |schema|
      feature = schema.features.detect {|f| f.name == 'Dynamic::RecipientInfo::Feature'}
      next unless feature
      recipient_info_klass = schema.klasses.detect {|k| k.name == 'RecipientInfo'}

      if recipient_info_klass
        recipient_email_klass = schema.klasses.detect {|k| k.name == 'RecipientEmailAddress'}
        email_klass = recipient_email_klass.associations.detect {|a| a.name == 'emails'}&.target_klass if recipient_email_klass
        recipient_phone_klass = schema.klasses.detect {|k| k.name == 'RecipientPhoneNumber'}
        phone_klass = recipient_email_klass.associations.detect {|a| a.name == 'phones'}&.target_klass if recipient_phone_klass
        address_klass = schema.klasses.detect {|k| k.name == 'Address'}
      end

      feature.options.create!([
        {
          name: 'email_klass',
          human_name_en: 'Table des E-mails',
          human_name_fr: "E-mails Table",
          type: 'String',
          coder_type: 'Dynamic::Schema::Option::Coder::Klass',
          value: email_klass&.id
        },
        {
          name: 'phone_klass',
          human_name_en: 'Table des téléphones',
          human_name_fr: "Phones Table",
          type: 'String',
          coder_type: 'Dynamic::Schema::Option::Coder::Klass',
          value: phone_klass&.id
        },
        {
          name: 'address_klass',
          human_name_en: 'Table des adresses',
          human_name_fr: "Address Table",
          type: 'String',
          coder_type: 'Dynamic::Schema::Option::Coder::Klass',
          value: address_klass&.id
        },
      ])
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
