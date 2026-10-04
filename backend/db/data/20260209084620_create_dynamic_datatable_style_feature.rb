# frozen_string_literal: true

class CreateDynamicDatatableStyleFeature < ActiveRecord::Migration[6.0]
  def up
    Dynamic::Schema.find_each do |s|
      next if s.features.where(name: 'Dynamic::Datatable::Style::Feature').exists?
      s.create_feature('Dynamic::Datatable::Style::Feature')
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
