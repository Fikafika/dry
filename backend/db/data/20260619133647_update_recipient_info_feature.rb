# frozen_string_literal: true

class UpdateRecipientInfoFeature < ActiveRecord::Migration[8.0]

  CONCERN_ATTRIBUTES_BY_NAME = {
    'RecipientEmailAddress' => {
      human_name_fr: 'E-mail unique',
      human_name_en: 'Unique e-mail',
    },
    'RecipientPhoneNumber' => {
      human_name_fr: 'Téléphone unique',
      human_name_en: 'Unique phone',
    },
  }.freeze

  def up
    Dynamic::Schema.find_each do |schema|
      feature = schema.features.find_by(name: 'Dynamic::RecipientInfo::Feature')
      next unless feature&.enabled

      CONCERN_ATTRIBUTES_BY_NAME.each do |k, v|
        klass = schema.klasses.detect {|kla| kla.name == k}
        feature.concerns.create_with(v.merge(klass: klass)).find_or_create_by!(name: k)
      end

      concerns = feature.concerns.select {|c| c.name.in?(['EmailAddress', 'PhoneNumber', 'Address'])}
      concerns.each do |c|
        c.human_name_fr = c.human_name_fr.gsub(' unique', '')
        c.human_name_en = c.human_name_en.gsub('Unique ', '')
        c.save!
      end

      opt_names = ['email_klass', 'phone_klass', 'address_klass']
      feature.options.select {|o| o.destroy if o.name.in?(opt_names)}
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
