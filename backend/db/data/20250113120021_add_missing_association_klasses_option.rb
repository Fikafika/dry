# frozen_string_literal: true

class AddMissingAssociationKlassesOption < ActiveRecord::Migration[6.0]
  def up
    Dynamic::Schema.find_each do |schema|
      mail_hosting_feature = schema.features.find_by(name: 'Dynamic::MailHosting::Feature')
      next unless mail_hosting_feature

      option = mail_hosting_feature.options.find_by(name: 'associations_klasses')

      mail_hosting_feature.options.create!(
        name: 'associations_klasses',
        human_name_en: 'Classes with associations',
        human_name_fr: 'Classes avec associations',
        type: 'String',
        coder_type: 'Dynamic::Schema::Option::Coder::Klasses',
        value: nil
      ) unless option
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
