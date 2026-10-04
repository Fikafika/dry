class AddLockedToSchemas < ActiveRecord::Migration[8.0]
  def change

    change_table :dynamic_schemas do |t|
      t.boolean :locked, default: false unless t.column_exists?(:locked)
    end

    change_table :dynamic_schema_klasses do |t|
      t.boolean :locked, default: false unless t.column_exists?(:locked)
    end

    change_table :dynamic_schema_attributes do |t|
      t.boolean :locked, default: false unless t.column_exists?(:locked)
    end

    change_table :dynamic_schema_attribute_enum_values do |t|
      t.boolean :locked, default: false unless t.column_exists?(:locked)
    end

    change_table :dynamic_schema_associations do |t|
      t.boolean :locked, default: false unless t.column_exists?(:locked)
    end

    change_table :dynamic_schema_attachments do |t|
      t.boolean :locked, default: false unless t.column_exists?(:locked)
    end

    change_table :dynamic_schema_attachment_variants do |t|
      t.boolean :locked, default: false unless t.column_exists?(:locked)
    end

    change_table :dynamic_schema_validations do |t|
      t.boolean :locked, default: false unless t.column_exists?(:locked)
    end

    change_table :dynamic_schema_normalizations do |t|
      t.boolean :locked, default: false unless t.column_exists?(:locked)
    end

    change_table :dynamic_schema_sequences do |t|
      t.boolean :locked, default: false unless t.column_exists?(:locked)
    end

    change_table :dynamic_schema_features do |t|
      t.boolean :locked, default: false unless t.column_exists?(:locked)
    end

    change_table :dynamic_schema_concerns do |t|
      t.boolean :locked, default: false unless t.column_exists?(:locked)
    end

    change_table :dynamic_schema_options do |t|
      t.boolean :locked, default: false unless t.column_exists?(:locked)
    end

  end
end
