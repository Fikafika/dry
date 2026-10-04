class CreateDynamicSchema < ActiveRecord::Migration[6.0]

  def change
    enable_extensions

    create_function :formatted_base_26
    create_function :compute_incremental_field
    create_function :compute_format
    create_function :format_increment

    create_table :dynamic_schemas, **table_options do |t|
      t.string :name
      t.timestamps
      t.datetime :deleted_at, index: true
      t.index [:name], where: 'deleted_at IS NULL', unique: true, name: 'uniq_index_dynamic_schemas'
    end

    create_table :dynamic_schema_klasses, **table_options do |t|
      t.string :permalink, index: true
      t.string :name
      t.string :const_table_name
      t.string :original_const_table_name
      t.string :route_key, null: false
      t.belongs_to :schema, null: false, index: true, type: id_type
      t.belongs_to :superklass, index: true, type: id_type
      t.belongs_to :baseklass, index: true, type: id_type
      t.integer :depth
      t.boolean :versioned, default: true
      t.integer :table_profile, default: 20
      t.timestamps
      t.datetime :deleted_at, index: true
      t.index [:schema_id, :name], where: 'deleted_at IS NULL', unique: true, name: 'uniq_index_dynamic_schema_klasses'
      t.index [:schema_id, :route_key], where: 'deleted_at IS NULL', unique: true, name: 'uniq_index_dynamic_schema_klasses_route_key'
    end

    create_table :dynamic_schema_attributes, **table_options do |t|
      t.string :name
      t.integer :column
      t.belongs_to :schema, null: false, index: true, type: id_type
      t.belongs_to :klass, index: true, type: id_type
      t.belongs_to :baseklass, index: true, type: id_type
      t.boolean :index, :default => false
      t.boolean :incremental, :default => false
      t.string :type, index: true
      t.timestamps
      t.datetime :deleted_at, index: true
      t.index [:schema_id, :klass_id, :name], where: 'deleted_at IS NULL', unique: true, name: 'uniq_index_dynamic_schema_attributes'
    end

    create_table :dynamic_schema_attribute_enum_values, **table_options do |t|
      t.uuid :uuid, null: false
      t.string :name
      t.belongs_to :schema, null: false, index: true, type: id_type
      t.belongs_to :attr, null: false, index: true, type: id_type
      t.timestamps
      t.datetime :deleted_at, index: true
    end

    create_table :dynamic_schema_attribute_enum_value_translations, **table_options do |t|
      t.belongs_to :schema, null: false, index: {name: 'index_dynamic_schema_attr_enum_value_tr_schema_id'}, type: id_type
      t.references :dynamic_schema_attribute_enum_value, index: {name: 'index_dynamic_schema_attribute_enum_value_id'}, type: id_type
      t.string :human_name
      t.string :locale
    end

    create_table :dynamic_schema_associations, **table_options do |t|
      t.string :name
      t.belongs_to :schema, null: false, index: true, type: id_type
      t.belongs_to :target_klass, index: true, type: id_type
      t.belongs_to :owner_klass, index: true, type: id_type
      t.references :inverse_of, index: {name: 'index_dynamic_schema_associations_on_inverse_id'}, type: id_type
      t.string :type, index: true
      t.timestamps
      t.datetime :deleted_at, index: true
      t.index [:schema_id, :owner_klass_id, :name], where: 'deleted_at IS NULL', unique: true, name: 'uniq_index_dynamic_schema_associations'
    end

    create_table :dynamic_schema_attachments, **table_options do |t|
      t.string :name
      t.belongs_to :schema, null: false, index: true, type: id_type
      t.belongs_to :owner_klass, index: true, type: id_type
      t.string :type, index: true
      t.timestamps
      t.datetime :deleted_at, index: true
      t.index [:schema_id, :owner_klass_id, :name], where: 'deleted_at IS NULL', unique: true, name: 'uniq_index_dynamic_schema_attachments'
    end

    create_table :dynamic_schema_translations, **table_options do |t|
      t.belongs_to :schema, null: false, index: true, type: id_type
      t.string :human_name
      t.string :locale
    end

    create_table :dynamic_schema_klass_translations, **table_options do |t|
      t.belongs_to :schema, null: false, index: true, type: id_type
      t.references :dynamic_schema_klass, index: {name: 'index_dynamic_schema_klass_translations_klass_id'}, type: id_type
      t.string :human_name
      t.string :plural_human_name
      t.string :locale
    end

    create_table :dynamic_schema_attribute_translations, **table_options do |t|
      t.references :dynamic_schema_attribute, index: {name: 'index_dynamic_schema_attribute_translations_attribute_id'}, type: id_type
      t.string :human_name
      t.string :locale
      t.belongs_to :schema, index: true, type: id_type
    end

    create_table :dynamic_schema_association_translations, **table_options do |t|
      t.references :dynamic_schema_association, index: {name: 'index_dynamic_schema_association_translations_association_id'}, type: id_type
      t.string :human_name
      t.string :locale
      t.belongs_to :schema, index: true, type: id_type
    end

    create_table :dynamic_schema_attachment_translations, **table_options do |t|
      t.references :dynamic_schema_attachment, index: {name: 'index_dynamic_schema_attachment_translations_attachment_id'}, type: id_type
      t.string :human_name
      t.string :locale
      t.belongs_to :schema, index: true, type: id_type
    end

    create_table :dynamic_schema_sequences, **table_options do |t|
      t.belongs_to :schema, null: false, index: true, type: id_type
      t.belongs_to :attr, null: false, index: true, type: id_type
      t.belongs_to :condition_attr, index: {name: 'index_dynamic_schema_sequences_condition_attr_id'}, type: id_type
      t.belongs_to :condition_value, index: {name: 'index_dynamic_schema_sequences_condition_value_id'}, type: id_type
      t.string :name
      t.string :const_sequence_name
      t.string :original_const_sequence_name
      t.integer :start_value, default: 1
      t.string :prefix, default: ''
      t.string :suffix, default: ''
      t.integer :part1_type, default: 0
      t.integer :part1_length, default: 1
      t.integer :part2_type, default: 0
      t.integer :part2_length, default: 0
      t.integer :part3_type, default: 0
      t.integer :part3_length, default: 0
      t.text :comment
      t.timestamps
      t.datetime :deleted_at, index: true
    end

    create_table :dynamic_schema_sequence_translations, **table_options do |t|
      t.belongs_to :schema, null: false, index: true, type: id_type, index: {name: 'index_dynamic_schema_seq_translations_schema_id'}
      t.references :dynamic_schema_sequence, index: {name: 'index_dynamic_schema_seq_translations_attribute_id'}, type: id_type
      t.string :human_name
      t.string :locale
      t.timestamps
      t.datetime :deleted_at, index: true, index: {name: 'index_dynamic_schema_seq_translations_deleted_at_id'}
    end

    create_table :dynamic_schema_features, **table_options do |t|
      t.string :name
      t.belongs_to :schema, null: false, index: true, type: id_type
      t.boolean :enabled, default: true
      t.boolean :visible, default: true
      t.boolean :mandatory, default: false
      t.integer :dependency_order
      t.string :type, index: true
      t.timestamps
      t.datetime :deleted_at, index: true
      t.index [:schema_id, :name], where: 'deleted_at IS NULL', unique: true, name: 'uniq_index_dynamic_schema_features'
    end

    create_table :dynamic_schema_feature_translations, **table_options do |t|
      t.references :dynamic_schema_feature, index: {name: 'index_dynamic_schema_feature_translations_feature_id'}, type: id_type
      t.string :human_name
      t.string :locale
      t.belongs_to :schema, index: true, type: id_type
    end

    create_table :dynamic_schema_concerns, **table_options do |t|
      t.string :name
      t.belongs_to :schema, null: false, index: true, type: id_type
      t.belongs_to :klass, index: true, type: id_type
      t.belongs_to :feature, index: true, type: id_type
      t.boolean :template, default: false
      t.string :type, index: true
      t.timestamps
      t.datetime :deleted_at, index: true
      t.index [:schema_id, :klass_id, :feature_id, :name], where: 'deleted_at IS NULL', unique: true, name: 'uniq_index_dynamic_schema_concerns'
    end

    create_table :dynamic_schema_concern_translations, **table_options do |t|
      t.references :dynamic_schema_concern, index: {name: 'index_dynamic_schema_concern_translations_concern_id'}, type: id_type
      t.string :human_name
      t.string :locale
      t.belongs_to :schema, index: true, type: id_type
    end

    create_table :dynamic_schema_options, **table_options do |t|
      t.belongs_to :schema, null: false, index: true, type: id_type
      t.belongs_to :owner,  null: false, polymorphic: true, type: id_type, index: {name: 'index_dynamic_schema_options_owner'}
      t.string :value_string
      t.json :value_json
      t.integer :value_integer
      t.boolean :value_boolean
      t.float :value_float
      t.text :value_text
      t.string :name
      t.boolean :visible, default: true
      t.string :type
      t.timestamps
      t.datetime :deleted_at, index: true
    end

    create_table :dynamic_schema_option_translations, **table_options do |t|
      t.references :dynamic_schema_option, index: {name: 'dynamic_schema_option_translations_id'}, type: id_type
      t.string :human_name
      t.string :locale
      t.belongs_to :schema, index: true, type: id_type
    end

    create_table :dynamic_schema_migrations, **table_options do |t|
      t.string :name
      t.integer :state, default: 0, index: true
      t.integer :progress, default: 0
      t.integer :total, default: 1
      t.belongs_to :schema, null: false, index: true, type: id_type
      t.belongs_to :klass, type: id_type
      t.belongs_to :attr, type: id_type
      t.string :source_attribute_type
      t.integer :source_attribute_column
      t.boolean :source_attribute_index
      t.string :target_attribute_type
      t.integer :target_attribute_column
      t.boolean :target_attribute_index
      t.string :type, index: true
      t.datetime :started_at
      t.datetime :finished_at
      t.timestamps
      t.datetime :deleted_at, index: true
    end

    create_table :dynamic_schema_migration_translations, **table_options do |t|
      t.references :dynamic_schema_migration, index: {name: 'index_dynamic_schema_migration_translations_id'}, type: id_type
      t.string :human_name
      t.string :locale
      t.belongs_to :schema, index: true, type: id_type
    end

    create_table :dynamic_schema_validations, **table_options do |t|
      t.string :name
      t.string :type, index: true
      t.string :expression, index: true
      t.string :operator
      t.string :comparison_value
      t.belongs_to :schema, null: false, index: true, type: id_type
      t.belongs_to :klass, index: true, type: id_type
      t.belongs_to :attr, index: true, type: id_type
      t.belongs_to :comparison_attr, index: true, type: id_type
      t.timestamps
      t.datetime :deleted_at, index: true
      t.index [:schema_id, :klass_id, :attr_id], where: 'deleted_at IS NULL', name: 'index_dynamic_schema_validations'
    end

    create_table :dynamic_schema_validation_translations, **table_options do |t|
      t.belongs_to :schema, null: false, index: true, type: id_type
      t.references :dynamic_schema_validation, index: {name: 'index_dynamic_schema_validation_translations_attribute_id'}, type: id_type
      t.string :human_name
      t.string :locale
      t.timestamps
      t.datetime :deleted_at, index: true
    end

    unless ActiveRecord::Base.connection.data_source_exists? 'active_storage_blobs'

      create_table :active_storage_blobs, **table_options do |t|
        t.string   :key,          null: false
        t.string   :filename,     null: false
        t.string   :content_type
        t.text     :metadata
        t.string   :service_name#, null: false # uncomment for rails >= 6.1
        t.bigint   :byte_size,    null: false
        t.string   :checksum,     null: false
        t.datetime :created_at,   null: false

        t.index [ :key ], unique: true
      end

      create_table :active_storage_attachments, **table_options do |t|
        t.string     :name,     null: false
        t.references :record,   null: false, polymorphic: true, index: false, type: id_type
        t.references :blob,     null: false, type: id_type

        t.datetime :created_at, null: false

        t.index [ :record_type, :record_id, :name, :blob_id ], name: "index_active_storage_attachments_uniqueness", unique: true
        t.foreign_key :active_storage_blobs, column: :blob_id
      end

      create_table :active_storage_variant_records, **table_options do |t|
        t.belongs_to :blob, null: false, index: false, type: id_type
        t.string :variation_digest, null: false

        t.index %i[ blob_id variation_digest ], name: "index_active_storage_variant_records_uniqueness", unique: true
        t.foreign_key :active_storage_blobs, column: :blob_id
      end

    end

  end

  def enable_extensions
    if id_type == :uuid && ActiveRecord::Base.connection.adapter_name.downcase == 'postgresql'
      enable_extension 'uuid-ossp' unless extension_enabled?('uuid-ossp')
      enable_extension 'pgcrypto' unless extension_enabled?('pgcrypto')
    end
  end

  def table_options
    id_type == :uuid ? {id: :uuid} : {}
  end

  def id_type
    :uuid
  end

end
