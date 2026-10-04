# frozen_string_literal: true

class AddCommentsToTransactionSchema < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      feature = schema.features.detect {|f| f.name == 'Dynamic::Transaction::Feature'}
      return unless feature&.enabled

      transaction_klass = feature.concerns.detect {|c| c.name == 'Base'}&.klass

      product_feature = schema.features.detect {|f| f.name == 'Dynamic::Product::Feature'}
      product_property_value_klass = feature.schema.klasses.detect {|k| k.name == 'ProductPropertyValue'}
      article_klass = product_feature.concerns.detect {|k| k.name == 'Article'}.klass

      [transaction_klass, product_property_value_klass, article_klass].compact.each do |k|
        ['amount_including_vat', 'amount_excluding_vat', 'vat_amount'].each do |attr_name|
          attr = k.attributes.detect {|a| a.name == attr_name}
          attr.update!(comment: 'Calculé implicitement') if attr
        end
      end

      applied_amount_klass = feature.schema.klasses.detect {|k| k.name == 'AppliedAmount'}&.klass
      applied_amount_klass&.update!(comment: 'Correspond aux remises ou charges calculées et positionnées pour une ligne de transaction ou une transaction')

      invoice_schedule_klass = feature.schema.klasses.detect {|k| k.name == 'InvoiceSchedule'}&.klass
      next unless invoice_schedule_klass
      attr = invoice_schedule_klass.attrs.detect {|a| a.name == 'amount'}
      attr&.update!(comment: "Est calculé implicitement si un Montant maximum par échéance ou un Nombre d'échéance est spécifié lors de la création")
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
