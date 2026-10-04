# frozen_string_literal: true

class ChangeDefaultValueToDynamicSchemaAttributeProtocols < ActiveRecord::Migration[8.0]
  def up
    ActiveRecord::Base.connection.execute('UPDATE dynamic_schema_attributes SET protocols = 0 WHERE protocols IS NULL')
  end

  def down
  end
end
