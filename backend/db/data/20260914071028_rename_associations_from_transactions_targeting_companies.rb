# frozen_string_literal: true

class RenameAssociationsFromTransactionsTargetingCompanies < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      feature = schema.features.detect {|f| f.name == 'Dynamic::Transaction::Feature'}
      next unless feature&.enabled

      concern = feature.concerns.detect {|c| c.name == 'Base'}
      next unless concern&.klass

      buyer_assoc = concern.klass.associations.detect {|a| a.name == 'buyer_company'}
      seller_assoc = concern.klass.associations.detect {|a| a.name == 'seller_company'}

      buyer_assoc&.update!(
        name: 'buyer_company',
        human_name_fr: 'Etablissement acheteur',
        human_name_en: 'Buyer establishment',
      )

      seller_assoc&.update!(
        name: 'seller_company',
        human_name_fr: 'Etablissement vendeur',
        human_name_en: 'Seller establishment',
      )
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
