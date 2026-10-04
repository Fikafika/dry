# frozen_string_literal: true

class RemoveNewsletterDeliveryKlass < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      feature = schema.features.detect {|f| f.name == 'Dynamic::Knewsletter::Feature'}
      next unless feature&.enabled
      option = feature.options.detect {|o| o.name == 'delivery_klass_name'}
      next unless option
      klass = schema.klasses.detect {|k| k.name == option.value}
      Dynamic::Schema::Association::Base.where(target_klass: klass).destroy_all
      klass.destroy!
      option.destroy!
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
