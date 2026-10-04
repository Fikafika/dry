# frozen_string_literal: true

class RemoveOpeningPercentageFromKnewsletterFeature < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      feature = schema.features.find_by(name: 'Dynamic::Knewsletter::Feature')
      next unless feature&.enabled?

      newsletter_klass_name = feature.options.find_by(name: 'newsletter_klass_name')&.value || 'Newsletter'
      newsletter_schema_klass = schema.klasses.find_by(name: newsletter_klass_name)
      next unless newsletter_schema_klass

      newsletter_schema_klass.attrs.where(name: 'opening_percentage').destroy_all
    end
  end

  def down
    Dynamic::Schema.find_each do |schema|
      feature = schema.features.find_by(name: 'Dynamic::Knewsletter::Feature')
      next unless feature&.enabled?

      newsletter_klass_name = feature.options.find_by(name: 'newsletter_klass_name')&.value || 'Newsletter'
      newsletter_schema_klass = schema.klasses.find_by(name: newsletter_klass_name)
      next unless newsletter_schema_klass

      next if newsletter_schema_klass.attrs.where(name: 'opening_percentage').exists?

      newsletter_schema_klass.attrs.create!(
        name: 'opening_percentage',
        human_name_fr: "Pourcentage d'ouverture",
        human_name_en: 'Opening percentage',
        type: 'Float'
      )
    end
  end
end
