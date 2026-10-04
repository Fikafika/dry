# frozen_string_literal: true

class NilifyBlankFormulas < ActiveRecord::Migration[6.0]
  def up
    [Dynamic::Schema::Attribute::Base, Dynamic::Schema::Association::Base].each do |k|
      k.with_deleted.where(formula: '').update_all(formula: nil)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
