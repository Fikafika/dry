class AddNameAttributeToDynamicSchemaKlasses < ActiveRecord::Migration[6.0]
  def change
    add_reference :dynamic_schema_klasses, :name_attribute, type: :uuid
    add_reference :dynamic_schema_klasses, :photo_attachment, type: :uuid
  end
end
