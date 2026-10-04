class CreateDataMigrationsTable < ActiveRecord::Migration[6.0]
  def up
    DataMigrate::RailsHelper.data_schema_migration.create_table
  end
end
