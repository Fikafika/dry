# frozen_string_literal: true

class AddSynchronizationOptionToPhoneDataFeature < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      feature = schema.features.detect {|f| f.name == 'Dynamic::PhoneData::Feature'}
      next unless feature
      option = feature.options.detect {|o| o.name == 'synchronize_phone_data_after_enable'}
      next if option
      feature.options.create!(
        name: 'synchronize_phone_data_after_enable',
        human_name_en: 'Synchroniser les données de téléphones après activation de la feature',
        human_name_fr: "Synchonize phone data after enabling feature",
        type: 'Boolean',
        value: false
      )
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
