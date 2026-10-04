class CreateDynamicForm < ActiveRecord::Migration[6.0]

  def change
    create_table :dynamic_forms, id: :uuid do |t|
      t.belongs_to :schema, null: false, index: true, type: :uuid

      t.string :klass_name # TODO replace by :source_klass_name

      t.string :association_klass_name # TODO replace by :target_klass_anme
      t.string :association_name

      t.integer :actions
      t.integer :mode, default: 0, null: false

      t.string :source_klass_name, index: true
      t.string :target_klass_name, index: true

      t.integer :column_count, default: 1

      t.boolean :hide_empty_inputs, default: false

      t.text :final_redirect_url

      t.string :lang

      t.boolean :auto_submission, default: false

      t.timestamps
      t.datetime :deleted_at, index: true
    end

    create_table :dynamic_form_translations, id: :uuid  do |t|
      t.belongs_to :schema, null: false, index: true, type: :uuid
      t.references :dynamic_form, index: {name: 'index_dynamic_form_translations_id'}, type: :uuid
      t.string :human_name
      t.string :locale
    end

    create_table :dynamic_form_elements, id: :uuid do |t|
      t.uuid :uuid, default: "gen_random_uuid()", null: false, index: true # TODO remove separate uuid column if :uuid == :uuid

      t.string :type
      t.belongs_to :schema, null: false, index: true, type: :uuid
      t.belongs_to :form, null: false, index: true, type: :uuid

      t.integer :requirement, default: 0
      t.string :editor
      t.integer :mode

      t.integer :position

      t.string :attribute_name
      t.string :klass_name
      t.text :target_klass_names

      t.string :root_klass_name
      t.text :method_names
      t.belongs_to :schema_instance, type: :uuid

      t.boolean :show_label, default: true

      t.integer :value_position, default: 0
      t.boolean :show_value, default: true

      t.boolean :disabled, default: 0
      t.boolean :read_only, default: false

      t.boolean :show_favorite, default: false
      t.boolean :favorite_never_disabled, default: false

      t.integer :autocomplete_mode, default: 0
      t.text :autocomplete_context
      t.boolean :autocomplete_disable_elements, default: true
      t.boolean :can_autocomplete_value

      t.belongs_to :parent, index: true, type: :uuid

      t.string :css_classes
      t.string :col_size
      t.string :label_col_size
      t.string :input_col_size

      t.boolean :show_previous_button, default: true
      t.boolean :show_next_button, default: true
      t.boolean :show_cancel_button, default: true
      t.boolean :show_submit_button, default: true

      t.text :default_value
      t.belongs_to :default_value_record, polymorphic: true, index: {name: 'index_d_form_elements_default_value_record_type_and_id'}, type: :uuid

      t.timestamps
      t.datetime :deleted_at, index: true
    end

    create_table :dynamic_form_element_translations, id: :uuid  do |t|
      t.belongs_to :schema, null: false, index: true
      t.references :dynamic_form_element, index: {name: 'index_dynamic_form_translations_element_id'}, type: :uuid
      t.string :label
      t.text :text
      t.text :help
      t.string :watermark
      t.text :translated_default_value
      t.string :previous_button_text
      t.string :next_button_text
      t.string :cancel_button_text
      t.string :submit_button_text
      t.string :locale
    end

    create_table :dynamic_form_schema_instances, id: :uuid do |t|
      t.belongs_to :schema, null: false, index: true, type: :uuid
      t.belongs_to :form, null: false, index: true, type: :uuid

      t.string :klass_name

      t.timestamps
      t.datetime :deleted_at, index: true
    end


    create_table :dynamic_form_schema_associations, id: :uuid do |t|
      t.string :type
      t.belongs_to :schema, null: false, index: true, type: :uuid
      t.belongs_to :form, null: false, index: true, type: :uuid

      t.belongs_to :owner_instance, index: true, type: :uuid
      t.belongs_to :target_instance, index: true, type: :uuid

      t.string :klass_name
      t.string :method_name

      t.boolean :merge, default: false

      t.timestamps
      t.datetime :deleted_at, index: true
    end

    create_table :dynamic_form_element_possible_values, id: :uuid do |t|
      t.belongs_to :schema, null: false, index: true, type: :uuid
      t.belongs_to :form, null: false,  index: true, type: :uuid
      t.belongs_to :element, null: false, index: true, type: :uuid

      t.text :value
      t.belongs_to :value_record, polymorphic: true, index: {name: 'index_d_form_element_possible_values_value_record_type_and_id'}, type: :uuid

      t.integer :position, default: 0

      t.timestamps
      t.datetime :deleted_at, index: true
    end

    create_table :dynamic_form_element_possible_value_translations, id: :uuid  do |t|
      t.belongs_to :schema, null: false, index: {name: 'index_d_form_element_possible_value_translations_schema_id'}, type: :uuid
      t.references :dynamic_form_element_possible_value, index: {name: 'index_dynamic_form_translations_possible_value_id'}, type: :uuid
      t.text :text
      t.text :original_text
      t.string :locale
    end

    create_table :dynamic_form_validation_rules, id: :uuid do |t|
      t.string :type
      t.belongs_to :schema, null: false, index: true, type: :uuid
      t.belongs_to :form, null: false, index: true, type: :uuid

      t.text :element_ids
      t.integer :requirement

      t.timestamps
      t.datetime :deleted_at, index: true
    end

    create_table :dynamic_form_page_rules, id: :uuid do |t|
      t.string :type
      t.belongs_to :schema, null: false, index: true, type: :uuid
      t.belongs_to :form, null: false, index: true, type: :uuid

      # TODO

      t.timestamps
      t.datetime :deleted_at, index: true
    end

    create_table :dynamic_form_submissions, id: :uuid do |t|
      t.belongs_to :schema, null: false, index: true, type: :uuid
      t.belongs_to :form, null: false, index: true, type: :uuid

      t.text :params
      t.text :original_params

      t.belongs_to :submitter, polymorphic: true, index: {name: 'index_dynamic_form_s_on_submitter_type_and_id' }, type: :uuid
      t.belongs_to :checker, polymorphic: true, index: {name: 'index_dynamic_form_s_on_checker_type_and_id' }, type: :uuid

      t.string :session_id
      t.string :ip_address
      t.string :user_agent

      t.integer :state, default: 0

      t.timestamps
      t.datetime :deleted_at, index: true

      t.index [:submitter_type, :submitter_id, :form_id], name: 'index_dynamic_form_s_on_submitter_type_and_id_and_form_id'
      t.index [:checker_type, :checker_id, :form_id], name: 'index_dynamic_form_s_on_checker_type_and_id_and_form_id'
    end

    create_table :dynamic_form_submission_records, id: :uuid do |t|
      t.belongs_to :schema, null: false, index: true, type: :uuid
      t.belongs_to :form, null: false, index: true, type: :uuid
      t.belongs_to :submission, null: false, index: true, type: :uuid
      t.belongs_to :schema_instance, null: false, index: true, type: :uuid

      t.belongs_to :record, polymorphic: true, index: {name: 'index_dynamic_form_submission_records_on_record_type_and_id' }, type: :uuid

      t.timestamps
      t.datetime :deleted_at, index: true
    end

  end

end
