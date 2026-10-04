# frozen_string_literal: true

class AddTransactionContactAssociationsToTransactionTables < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      feature = schema.features.detect {|f| f.name == 'Dynamic::Transaction::Feature'}
      next unless feature
      feature.options.create_with(
        human_name_fr: 'Table des comptes',
        human_name_en: 'Account Table',
        type: 'String',
        coder_type: 'Dynamic::Schema::Option::Coder::Klass',
        value: nil
      ).find_or_create_by!(name: 'account_klass')
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
