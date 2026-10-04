# frozen_string_literal: true

class AddFeaturesForCountryTimezonePhonedata < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      schema.create_feature('Dynamic::Country::Feature') unless schema.features.detect {|f| f.name ==  'Dynamic::Country::Feature'}
      schema.create_feature('Dynamic::Timezone::Feature') unless schema.features.detect {|f| f.name ==  'Dynamic::Timezone::Feature'}
      schema.create_feature('Dynamic::PhoneData::Feature') unless schema.features.detect {|f| f.name ==  'Dynamic::PhoneData::Feature'}
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
