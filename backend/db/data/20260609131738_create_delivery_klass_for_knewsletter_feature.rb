# frozen_string_literal: true

class CreateDeliveryKlassForKnewsletterFeature < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      feature = schema.features.detect {|f| f.name == 'Dynamic::Knewsletter::Feature'}
      next unless feature&.enabled

      concern = feature.concerns.detect {|c| c.name == 'NewsletterDelivery'}

      unless concern
        concern = feature.concerns.create!(
          name: 'NewsletterDelivery',
          human_name_fr: 'Livraison Newsletter',
          human_name_en: 'Newsletter delivery',
        )
      end
      next if concern.klass

      recipient_info_feature = feature.schema.features.detect {|f| f.name == 'Dynamic::RecipientInfo::Feature'}
      recipient_klass = recipient_info_feature.concerns.detect {|c| c.name == 'EmailAddress'}&.klass

      newsletter_klass = feature.concerns.detect {|c| c.name == 'Newsletter'}.klass

      klass = Dynamic::Knewsletter::Feature.create_delivery_klass(feature)
      Dynamic::Knewsletter::Feature.create_delivery_attributes(klass)
      Dynamic::Knewsletter::Feature.create_delivery_associations(klass, newsletter_klass, recipient_klass) if recipient_klass
      concern.update!(klass: klass)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
