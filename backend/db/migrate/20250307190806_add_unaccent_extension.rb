class AddUnaccentExtension < ActiveRecord::Migration[8.0]
  def change
    enable_extension 'unaccent' unless extension_enabled?('unaccent')
  end
end
