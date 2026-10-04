# frozen_string_literal: true

class AddTransmissionDateToTransactionTables < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      feature = schema.features.detect {|f| f.name == 'Dynamic::Transaction::Feature'}
      next unless feature
      transaction_concern = feature.concerns.detect {|o| o.name == 'Base'}
      next unless transaction_concern&.klass
      transaction_concern.klass.attrs.create_with(
        type: 'Date',
        human_name_fr: 'Date de transmission',
        human_name_en: 'Transmission date',
      ).find_or_create_by!(name: 'transmission_date')
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
