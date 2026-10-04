# frozen_string_literal: true

class AddGeneratedAttributeToTransactionLineInfos < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      feature = schema.features.detect {|f| f.name == 'Dynamic::Transaction::Feature'}
      next unless feature&.enabled

      tl_klass = feature.concerns.detect {|c| c.name == 'Line::Info'}.klass
      next unless tl_klass

      tl_klass.attrs.create_with(
        type: 'Boolean',
        human_name_fr: 'Généré',
        human_name_en: 'Generated',
        locked: true,
      ).find_or_create_by!(name: 'generated')
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
