# frozen_string_literal: true

class UpdatePhoneKlassNameOptionFromSmsFeature < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      feature = schema.features.detect {|f| f.name == 'Dynamic::Sms::Feature'}
      next unless feature
      option_phone_klass_name = feature.options.detect {|o| o.name.start_with?('#<D')}
      option_phone_klass_name.update!(name: 'phone_klass') if option_phone_klass_name
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
