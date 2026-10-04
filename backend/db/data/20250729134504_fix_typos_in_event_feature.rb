# frozen_string_literal: true

class FixTyposInEventFeature < ActiveRecord::Migration[8.0]
  def up
    ActiveRecord::Base.connection.execute("UPDATE dynamic_schema_option_translations SET human_name = 'Table évènement ciblé par l''association' WHERE human_name = 'Table évennement ciblé par l''association'")
    ActiveRecord::Base.connection.execute("UPDATE dynamic_schema_option_translations SET human_name = 'Event table targeted by association' WHERE human_name = 'Evant table targettted by association'")
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
