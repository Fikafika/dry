# frozen_string_literal: true

class RemoveLamFeature < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      feature = schema.features.detect {|f| f.name == 'Dynamic::Lam::Irec::Feature'}
      next unless feature
      feature.destroy!
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
