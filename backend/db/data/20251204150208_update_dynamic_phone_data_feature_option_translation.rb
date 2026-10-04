# frozen_string_literal: true

class UpdateDynamicPhoneDataFeatureOptionTranslation < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      feature = schema.features.detect {|f| f.name == 'Dynamic::PhoneData::Feature'}
      next unless feature
      opt = feature.options.detect {|e| e.name == 'synchronize_phone_data_after_enable'}
      if opt.human_name_fr == 'Synchonize phone data after enabling feature'
        opt.update!(name: opt.name, human_name_fr: opt.human_name_en, human_name_en: opt.human_name_fr)
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
