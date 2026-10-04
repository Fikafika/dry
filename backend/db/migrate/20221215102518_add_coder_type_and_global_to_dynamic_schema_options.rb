class AddCoderTypeAndGlobalToDynamicSchemaOptions < ActiveRecord::Migration[6.0]
  def change
    return if ActiveRecord::Base.connection.column_exists?(:dynamic_schema_options, :coder_type)
    change_table :dynamic_schema_options do |t|
      t.string :coder_type
      t.boolean :global, default: true
    end
  end
end
