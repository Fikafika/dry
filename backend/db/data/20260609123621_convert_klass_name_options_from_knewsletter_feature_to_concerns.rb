# frozen_string_literal: true

class ConvertKlassNameOptionsFromKnewsletterFeatureToConcerns < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      feature = schema.features.detect {|f| f.name == 'Dynamic::Knewsletter::Feature'}
      next unless feature&.enabled

      option_mapping = {
        'newsletter_klass_name' => {
          name: 'Newsletter',
          human_name_fr: 'Newsletter',
          human_name_en: 'Newsletter',
        },
        'link_klass_name' => {
          name: 'Link',
          human_name_fr: 'Lien newsletter',
          human_name_en: 'Newsletter link',
        },
        'visit_klass_name' => {
          name: 'Visit',
          human_name_fr: 'Visite Newsletter',
          human_name_en: 'Newsletter visit',
        },
      }

      option_mapping.each do |o_name, c_attrs|
        option = feature.options.detect {|o| o.name == o_name}
        next unless option
        klass_name = option.value
        klass = schema.klasses.detect {|k| k.name == klass_name}
        feature.concerns.create!(c_attrs.merge(klass: klass))
        option.destroy!
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
