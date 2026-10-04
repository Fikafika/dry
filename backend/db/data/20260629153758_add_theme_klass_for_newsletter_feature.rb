# frozen_string_literal: true

class AddThemeKlassForNewsletterFeature < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      feature = schema.features.detect {|f| f.name == 'Dynamic::Knewsletter::Feature'}
      next unless feature&.enabled

      opt_theme_klass = feature.options.detect {|o| o.name == 'theme_klass'}
      unless opt_theme_klass
        theme_klass = Dynamic::Knewsletter::Feature.create_theme_klass(feature)
        Dynamic::Knewsletter::Feature.create_theme_attributes(feature, theme_klass)
        Dynamic::Knewsletter::Feature.create_theme_associations(feature, theme_klass)

        feature.options.create!(
          name: 'theme_klass',
          human_name_fr: 'Table des thèmes de newsletter',
          human_name_en: "Newsletter theme table",
          type: 'String',
          coder_type: 'Dynamic::Schema::Option::Coder::Klass',
          value: theme_klass
        )
      end

      opt_theme_associations = feature.options.detect {|o| o.name == 'theme_associations_klasses'}
      unless opt_theme_associations
        feature.options.create!(
          name: 'theme_associations_klasses',
          human_name_en: 'Classes with theme associations',
          human_name_fr: 'Classes avec associations thèmes',
          type: 'String',
          coder_type: 'Dynamic::Schema::Option::Coder::Klasses',
          value: ''
        )
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
