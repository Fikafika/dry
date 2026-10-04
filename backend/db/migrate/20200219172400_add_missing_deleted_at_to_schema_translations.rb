class AddMissingDeletedAtToSchemaTranslations < ActiveRecord::Migration[8.0]
  def change
    add_timestamps :dynamic_schema_translations, if_not_exists: true, default: Time.zone.now
    change_column_default :dynamic_schema_translations, :created_at, nil
    change_column_default :dynamic_schema_translations, :updated_at, nil

    add_column :dynamic_schema_translations, :deleted_at, :datetime, if_not_exists: true
    add_index :dynamic_schema_translations, :deleted_at

    add_timestamps :dynamic_schema_klass_translations, if_not_exists: true, default: Time.zone.now
    change_column_default :dynamic_schema_klass_translations, :created_at, nil
    change_column_default :dynamic_schema_klass_translations, :updated_at, nil

    add_column :dynamic_schema_klass_translations, :deleted_at, :datetime, if_not_exists: true
    add_index :dynamic_schema_klass_translations, :deleted_at

    add_timestamps :dynamic_schema_attribute_translations, if_not_exists: true, default: Time.zone.now
    change_column_default :dynamic_schema_attribute_translations, :created_at, nil
    change_column_default :dynamic_schema_attribute_translations, :updated_at, nil

    add_column :dynamic_schema_attribute_translations, :deleted_at, :datetime, if_not_exists: true
    add_index :dynamic_schema_attribute_translations, :deleted_at

    add_timestamps :dynamic_schema_attribute_enum_value_translations, if_not_exists: true, default: Time.zone.now
    change_column_default :dynamic_schema_attribute_enum_value_translations, :created_at, nil
    change_column_default :dynamic_schema_attribute_enum_value_translations, :updated_at, nil

    add_column :dynamic_schema_attribute_enum_value_translations, :deleted_at, :datetime, if_not_exists: true
    add_index :dynamic_schema_attribute_enum_value_translations, :deleted_at, name: 'index_dynamic_schema_attribute_enum_value_translations'

    add_timestamps :dynamic_schema_attachment_translations, if_not_exists: true, default: Time.zone.now
    change_column_default :dynamic_schema_attachment_translations, :created_at, nil
    change_column_default :dynamic_schema_attachment_translations, :updated_at, nil

    add_column :dynamic_schema_attachment_translations, :deleted_at, :datetime, if_not_exists: true
    add_index :dynamic_schema_attachment_translations, :deleted_at

    add_timestamps :dynamic_schema_association_translations, if_not_exists: true, default: Time.zone.now
    change_column_default :dynamic_schema_association_translations, :created_at, nil
    change_column_default :dynamic_schema_association_translations, :updated_at, nil

    add_column :dynamic_schema_association_translations, :deleted_at, :datetime, if_not_exists: true
    add_index :dynamic_schema_association_translations, :deleted_at

    # dynamic_schema_validation_translations already have timestamps

    add_timestamps :dynamic_schema_feature_translations, if_not_exists: true, default: Time.zone.now
    change_column_default :dynamic_schema_feature_translations, :created_at, nil
    change_column_default :dynamic_schema_feature_translations, :updated_at, nil

    add_column :dynamic_schema_feature_translations, :deleted_at, :datetime, if_not_exists: true
    add_index :dynamic_schema_feature_translations, :deleted_at

    add_timestamps :dynamic_schema_concern_translations, if_not_exists: true, default: Time.zone.now
    change_column_default :dynamic_schema_concern_translations, :created_at, nil
    change_column_default :dynamic_schema_concern_translations, :updated_at, nil

    add_column :dynamic_schema_concern_translations, :deleted_at, :datetime, if_not_exists: true
    add_index :dynamic_schema_concern_translations, :deleted_at

    add_timestamps :dynamic_schema_option_translations, if_not_exists: true, default: Time.zone.now
    change_column_default :dynamic_schema_option_translations, :created_at, nil
    change_column_default :dynamic_schema_option_translations, :updated_at, nil

    add_column :dynamic_schema_option_translations, :deleted_at, :datetime, if_not_exists: true
    add_index :dynamic_schema_option_translations, :deleted_at

    add_timestamps :dynamic_schema_migration_translations, if_not_exists: true, default: Time.zone.now
    change_column_default :dynamic_schema_migration_translations, :created_at, nil
    change_column_default :dynamic_schema_migration_translations, :updated_at, nil

    add_column :dynamic_schema_migration_translations, :deleted_at, :datetime, if_not_exists: true
    add_index :dynamic_schema_migration_translations, :deleted_at
  end
end
