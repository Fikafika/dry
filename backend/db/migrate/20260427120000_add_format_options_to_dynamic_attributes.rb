class AddFormatOptionsToDynamicAttributes < ActiveRecord::Migration[6.0]
  def change
    change_table :dynamic_schema_attributes do |t|
      t.json :format_options, default: {}
    end
  end
end
