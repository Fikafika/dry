# frozen_string_literal: true

class MigrateRecipientsFromNewslettersToNewsletterDeliveries < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      feature = schema.features.detect {|f| f.name == 'Dynamic::Knewsletter::Feature'}
      next unless feature&.enabled

      newsletter_concern = feature.concerns.detect {|c| c.name == 'Newsletter'}
      delivery_concern = feature.concerns.detect {|c| c.name == 'NewsletterDelivery'}
      next unless newsletter_concern.klass && delivery_concern.klass

      recipients_assoc = newsletter_concern.klass.associations.detect {|a| a.name == 'recipients'}
      next unless recipients_assoc

      schema.load

      newsletter_concern.klass.const.find_each do |n|
        deliveries_attributes = n.recipients_associations.map do |a|
          {sent: true, delivery_date: a.created_at_from_uuid, recipient_id: a.association_target_id}
        end
        n.update!(
          recipient_ids: [],
          deliveries_attributes: deliveries_attributes
        )
      end

      recipients_assoc.inverse_of&.destroy!
      recipients_assoc.destroy!
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
