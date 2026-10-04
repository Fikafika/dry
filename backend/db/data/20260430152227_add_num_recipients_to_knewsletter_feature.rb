# frozen_string_literal: true

class AddNumRecipientsToKnewsletterFeature < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      feature = schema.features.find_by(name: 'Dynamic::Knewsletter::Feature')
      next unless feature&.enabled?

      newsletter_klass_name = feature.options.find_by(name: 'newsletter_klass_name')&.value || 'Newsletter'
      newsletter_schema_klass = schema.klasses.find_by(name: newsletter_klass_name)
      next unless newsletter_schema_klass

      next if newsletter_schema_klass.attrs.where(name: 'num_recipients').exists?
      newsletter_schema_klass.attrs.create!(
        name: 'num_recipients',
        human_name_fr: 'Nombre de destinataires',
        human_name_en: 'Number of Recipients',
        type: 'Integer'
      )
    end
  end

  def down
    Dynamic::Schema.find_each do |schema|
      feature = schema.features.find_by(name: 'Dynamic::Knewsletter::Feature')
      next unless feature

      newsletter_klass_name = feature.options.find_by(name: 'newsletter_klass_name')&.value || 'Newsletter'
      newsletter_klass = schema.klasses.find_by(name: newsletter_klass_name)
      next unless newsletter_klass

      newsletter_klass.attrs.where(name: 'num_recipients').destroy_all
    end
  end
end
