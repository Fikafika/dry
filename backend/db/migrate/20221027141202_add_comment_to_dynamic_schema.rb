class AddCommentToDynamicSchema < ActiveRecord::Migration[6.0]
  def change
    [
      :dynamic_schemas,
      :dynamic_schema_klasses,
      :dynamic_schema_attributes,
      :dynamic_schema_associations,
      :dynamic_schema_attachments,
      :dynamic_schema_attribute_enum_values,
      :dynamic_schema_validations,
      :dynamic_schema_features,
      :dynamic_schema_concerns,
      :dynamic_schema_migrations,
    ].each do |t|
      add_column t, :comment, :text
    end
  end
end
