# frozen_string_literal: true

class CreateTextAttributeForNewsletterLink < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      feature = schema.features.detect {|f| f.name == 'Dynamic::Knewsletter::Feature'}
      next unless feature&.enabled

      newsletter_concern = feature.concerns.detect {|c| c.name == 'Link'}
      newsletter_concern.klass.attrs.create_with(
        human_name_fr: 'Texte',
        human_name_en: 'Text',
        type: 'Text',
      ).find_or_create_by!(
        name: 'text',
      )
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
