# frozen_string_literal: true

class RemoveEmptyDashboards < ActiveRecord::Migration[6.0]
  def up
     Dynamic::Schema.find_each do |schema|
      schema.unload; schema.load
      dashboard_klass = schema.const::R::Dashboard
      dashboard_klass.left_joins(:charts).where(charts: {id: nil}).delete_all
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
