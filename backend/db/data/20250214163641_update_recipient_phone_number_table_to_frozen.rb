# frozen_string_literal: true

class UpdateRecipientPhoneNumberTableToFrozen < ActiveRecord::Migration[6.0]
  def up
    Dynamic::Schema.find_each do |schema|
      recipient_phone_klass = schema.klasses.detect {|k| k.name == 'RecipientPhoneNumber'}
      next unless recipient_phone_klass
      next if recipient_phone_klass.frozen_table?
      recipient_phone_klass.send(:migrate_to_frozen_table)
      recipient_phone_klass.update!(frozen_table: true)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
