class CastWhodunnitToUuidInVersions < ActiveRecord::Migration[8.0]
  def up
    ActiveRecord::Base.connection.tables.each do |table_name|
      next unless table_name.start_with?('d_') && table_name.end_with?('_versions')
      change_column table_name, :whodunnit, :uuid, using: 'whodunnit::uuid'
      # TODO add index to event !!!
    end
  end

  def down
  end
end
