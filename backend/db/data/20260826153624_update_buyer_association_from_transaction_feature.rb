# frozen_string_literal: true

class UpdateBuyerAssociationFromTransactionFeature < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      feature = schema.features.detect {|f| f.name == 'Dynamic::Transaction::Feature'}
      next unless feature&.enabled

      concern = feature.concerns.detect {|c| c.name == 'Base'}
      assoc = concern.klass.associations.detect {|a| a.name == 'buyer'}
      next unless assoc

      assoc.update!(
        name: 'buyer_contact',
        human_name_fr: 'Contact Acheteur',
        human_name_en: 'Buyer Contact',
      )

      option = feature.options.detect {|o| o.name == 'contact_klass'}
      contact_klass = option.value
      next unless contact_klass

      contact_transaction = contact_klass.associations.detect {|a| a.name == 'transactions'}
      contact_transaction.update!(inverse_of: assoc)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
