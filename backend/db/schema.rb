# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_10_02_120000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"
  enable_extension "unaccent"
  enable_extension "uuid-ossp"

  create_function :uuid_generate_v7, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.uuid_generate_v7()
       RETURNS uuid
       LANGUAGE plpgsql
      AS $function$
      declare
        output       bytea = e'\\000\\000\\000\\000\\000\\000\\000\\000\\000';
        timestamp    timestamptz;
        unix_ts_ms   bigint;
        rand_a       int;
      begin
        timestamp = clock_timestamp();
        unix_ts_ms = floor(extract(epoch from timestamp) * 1000)::bigint;

        output = set_byte(output, 0, (unix_ts_ms >> 40)::bit(8)::int);
        output = set_byte(output, 1, (unix_ts_ms >> 32)::bit(8)::int);
        output = set_byte(output, 2, (unix_ts_ms >> 24)::bit(8)::int);
        output = set_byte(output, 3, (unix_ts_ms >> 16)::bit(8)::int);
        output = set_byte(output, 4, (unix_ts_ms >> 8)::bit(8)::int);
        output = set_byte(output, 5, unix_ts_ms::bit(8)::int);

        /* use milliseconds as a "fixed-length dedicated counter" in order to improve monotonicity (https://datatracker.ietf.org/doc/html/draft-peabody-dispatch-new-uuid-format-03#section-6.2 Method 1) */
        rand_a = floor((extract(epoch from timestamp) * 1000 - unix_ts_ms) * 1000)::int;

        output = set_byte(output, 6, (b'0111'||(rand_a >> 8)::bit(4))::bit(8)::int);
        output = set_byte(output, 7, rand_a::bit(8)::int);

        output = set_byte(output, 8, (b'10'||get_byte(gen_random_bytes(1), 0)::bit(6))::bit(8)::int);
        output = output || gen_random_bytes(7);

        return substring(output::text from 3)::uuid;
      end
      $function$
  SQL
  create_function :formatted_base_26, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.formatted_base_26(value bigint, nb_expected_char integer)
       RETURNS character varying
       LANGUAGE plpgsql
      AS $function$
      -- Convert an integer into letters
      DECLARE
        chars char[];
        ret varchar;
        val bigint;
      BEGIN
        chars := ARRAY['A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'];
        val := value;
        ret := '';
        IF val < 0 THEN
          val := val * -1;
        END IF;
        WHILE val != 0 LOOP
          ret := chars[(val % 26)+1] || ret;
          val := val / 26;
        END LOOP;
        IF nb_expected_char > 0 AND char_length(ret) < nb_expected_char THEN
          ret := lpad(ret, nb_expected_char, 'A');
        END IF;
        RETURN ret;
      END;
      $function$
  SQL
  create_function :compute_incremental_field, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.compute_incremental_field(prefix character varying, suffix character varying, sequence_name character varying, format1 integer, type1 integer, format2 integer, type2 integer, format3 integer, type3 integer)
       RETURNS character varying
       LANGUAGE plpgsql
      AS $function$
      -- Concatenate the prefix, the increment and the suffix
      BEGIN
        RETURN CONCAT(prefix, format_increment(sequence_name, format1, type1, format2, type2, format3, type3), suffix);
      END
      $function$
  SQL
  create_function :format_increment, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.format_increment(sequence_name character varying, format1 integer, type1 integer, format2 integer, type2 integer, format3 integer, type3 integer)
       RETURNS character varying
       LANGUAGE plpgsql
      AS $function$
      -- format the increment into the requested format
      -- type1, type2, type3  : if 0 -> integer format, if 1 -> characters format
      DECLARE
        value bigint;
        quotient1 bigint;
        rest1 bigint;
        quotient2 bigint;
        rest2 bigint;
      BEGIN
        value := nextval(sequence_name);
        IF format3>0 THEN
          IF type3=0 THEN
            rest1 := value%(CAST(10^(format3) AS integer));
            quotient1 := CAST(trunc(value/(10^format3)) AS bigint);
            rest2 := CAST(quotient1%(CAST((26^format2) AS integer)) AS bigint);
            quotient2 := CAST(trunc(quotient1/(26^format2)) AS bigint);
            RETURN CONCAT(to_char(quotient2, compute_format(format1)), formatted_base_26(rest2, format2), to_char(rest1, compute_format(format3)));
          ELSE
            rest1 := CAST(value%(CAST((26^format3) AS integer)) AS bigint);
            quotient1 := CAST(trunc(value/(26^format3)) AS bigint);
            rest2 := quotient1%(CAST(10^format2 AS integer));
            quotient2 := CAST(trunc(quotient1/(10^format2)) AS bigint);
            RETURN CONCAT(formatted_base_26(quotient2, format1), to_char(rest2, compute_format(format2)), formatted_base_26(rest1, format3));
          END IF;
        ELSIF format2>0 THEN
          IF type2=0 THEN
            rest1 := value%(CAST(10^format2 AS integer));
            quotient1 := CAST(trunc(value/(10^format2)) AS bigint);
            RETURN CONCAT(formatted_base_26(quotient1, format1), to_char(rest1, compute_format(format2)));
          ELSE
            rest1 := CAST(value%(CAST((26^format2) AS integer)) AS bigint);
            quotient1 := CAST(trunc(value/(26^format2)) AS bigint);
            RETURN CONCAT(to_char(quotient1, compute_format(format1)), formatted_base_26(rest1, format2));
          END IF;
        ELSIF type1=0 THEN
          RETURN to_char(value, compute_format(format1));
        ELSE
          RETURN formatted_base_26(value, format1);
        END IF;
      END
      $function$
  SQL
  create_function :compute_format, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.compute_format(format integer)
       RETURNS character varying
       LANGUAGE plpgsql
      AS $function$
      -- Convert the number of digits into an integer format
      BEGIN
        RETURN lpad('fm', format + 2, '0');
      END
      $function$
  SQL

  create_collation :case_insensitive, sql_definition: <<-'SQL'
      CREATE COLLATION IF NOT EXISTS case_insensitive (provider = icu, locale = 'und-u-ks-level2', deterministic = false)
  SQL

  create_table "active_storage_attachments", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.uuid "record_id", null: false
    t.uuid "blob_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name"
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", precision: nil, null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "cas_session_tickets", force: :cascade do |t|
    t.string "cas_service_ticket", limit: 255, null: false
    t.string "session_id", limit: 255, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cas_service_ticket"], name: "index_cas_session_tickets_on_cas_service_ticket", unique: true
    t.index ["updated_at"], name: "index_cas_session_tickets_on_updated_at"
  end

  create_table "communities", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "permalink", null: false
    t.uuid "parent_id"
    t.string "short_description"
    t.text "description"
    t.uuid "uneek_sso_uuid"
    t.string "uneek_sso_syncable_fingerprint"
    t.string "uneek_sso_client_syncable_fingerprint"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "schema_id", null: false
    t.uuid "theme_id"
    t.boolean "has_logo", default: false, null: false
    t.index ["parent_id"], name: "index_communities_on_parent_id"
    t.index ["permalink"], name: "index_communities_on_permalink", unique: true
    t.index ["schema_id"], name: "index_communities_on_schema_id"
    t.index ["theme_id"], name: "index_communities_on_theme_id"
    t.index ["uneek_sso_uuid"], name: "index_communities_on_uneek_sso_uuid", unique: true
  end

  create_table "data_migrations", primary_key: "version", id: :string, force: :cascade do |t|
  end

  create_table "dynamic_builder_edges", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.uuid "schema_id"
    t.uuid "builder_id"
    t.text "klass_name"
    t.text "association_name"
    t.uuid "source_node_id"
    t.uuid "target_node_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.index ["builder_id"], name: "index_dynamic_builder_edges_on_builder_id"
    t.index ["deleted_at"], name: "index_dynamic_builder_edges_on_deleted_at"
    t.index ["schema_id"], name: "index_dynamic_builder_edges_on_schema_id"
    t.index ["source_node_id"], name: "index_dynamic_builder_edges_on_source_node_id"
    t.index ["target_node_id"], name: "index_dynamic_builder_edges_on_target_node_id"
  end

  create_table "dynamic_builder_nodes", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.uuid "schema_id"
    t.uuid "builder_id"
    t.text "klass_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.index ["builder_id"], name: "index_dynamic_builder_nodes_on_builder_id"
    t.index ["deleted_at"], name: "index_dynamic_builder_nodes_on_deleted_at"
    t.index ["schema_id"], name: "index_dynamic_builder_nodes_on_schema_id"
  end

  create_table "dynamic_builder_options", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.uuid "schema_id"
    t.uuid "builder_id"
    t.uuid "node_id"
    t.text "method_name"
    t.boolean "when_create", default: true
    t.boolean "when_update", default: true
    t.boolean "when_destroy", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.index ["builder_id"], name: "index_dynamic_builder_options_on_builder_id"
    t.index ["deleted_at"], name: "index_dynamic_builder_options_on_deleted_at"
    t.index ["node_id"], name: "index_dynamic_builder_options_on_node_id"
    t.index ["schema_id"], name: "index_dynamic_builder_options_on_schema_id"
  end

  create_table "dynamic_builders", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.uuid "schema_id"
    t.string "owner_type"
    t.uuid "owner_id"
    t.text "klass_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.index ["deleted_at"], name: "index_dynamic_builders_on_deleted_at"
    t.index ["owner_type", "owner_id"], name: "index_dynamic_builders_on_owner_type_and_owner_id"
    t.index ["schema_id"], name: "index_dynamic_builders_on_schema_id"
  end

  create_table "dynamic_cascade_elements", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.uuid "schema_id"
    t.uuid "cascade_id"
    t.uuid "level_id"
    t.text "method_name"
    t.string "object_type"
    t.uuid "object_id"
    t.datetime "updated_at", precision: nil
    t.datetime "deleted_at", precision: nil
    t.index ["cascade_id"], name: "index_dynamic_cascade_elements_on_cascade_id"
    t.index ["deleted_at"], name: "index_dynamic_cascade_elements_on_deleted_at"
    t.index ["level_id"], name: "index_dynamic_cascade_elements_on_level_id"
    t.index ["object_type", "object_id"], name: "index_dynamic_cascade_elements_on_object_type_and_object_id"
    t.index ["schema_id"], name: "index_dynamic_cascade_elements_on_schema_id"
  end

  create_table "dynamic_cascade_levels", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.uuid "schema_id"
    t.uuid "cascade_id"
    t.integer "depth", default: 0
    t.datetime "updated_at", precision: nil
    t.datetime "deleted_at", precision: nil
    t.index ["cascade_id"], name: "index_dynamic_cascade_levels_on_cascade_id"
    t.index ["deleted_at"], name: "index_dynamic_cascade_levels_on_deleted_at"
    t.index ["schema_id"], name: "index_dynamic_cascade_levels_on_schema_id"
  end

  create_table "dynamic_cascades", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.string "owner_type"
    t.uuid "owner_id"
    t.uuid "schema_id"
    t.uuid "klass_id"
    t.uuid "assoc_id"
    t.datetime "updated_at", precision: nil
    t.datetime "deleted_at", precision: nil
    t.string "type"
    t.index ["assoc_id"], name: "index_dynamic_cascades_on_assoc_id"
    t.index ["deleted_at"], name: "index_dynamic_cascades_on_deleted_at"
    t.index ["klass_id"], name: "index_dynamic_cascades_on_klass_id"
    t.index ["owner_id", "owner_type", "klass_id"], name: "index_dynamic_cascades_on_owner_id_and_owner_type_and_klass_id"
    t.index ["owner_type", "owner_id"], name: "index_dynamic_cascades_on_owner_type_and_owner_id"
    t.index ["schema_id", "klass_id"], name: "index_dynamic_cascades_on_schema_id_and_klass_id"
    t.index ["schema_id"], name: "index_dynamic_cascades_on_schema_id"
  end

  create_table "dynamic_form_default_value_associations", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.uuid "schema_id", null: false
    t.uuid "form_id", null: false
    t.uuid "element_id", null: false
    t.string "record_type"
    t.uuid "record_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_dynamic_form_default_value_associations_on_deleted_at"
    t.index ["element_id"], name: "index_dynamic_form_default_value_associations_on_element_id"
    t.index ["form_id"], name: "index_dynamic_form_default_value_associations_on_form_id"
    t.index ["record_type", "record_id"], name: "index_dynamic_form_dva_record_type_and_id"
    t.index ["schema_id"], name: "index_dynamic_form_default_value_associations_on_schema_id"
  end

  create_table "dynamic_form_element_possible_value_translations", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.uuid "schema_id", null: false
    t.uuid "dynamic_form_element_possible_value_id"
    t.text "text"
    t.text "original_text"
    t.string "locale"
    t.datetime "deleted_at", precision: nil
    t.index ["deleted_at"], name: "index_d_form_element_possible_value_translations_on_deleted_at"
    t.index ["dynamic_form_element_possible_value_id"], name: "index_dynamic_form_translations_possible_value_id"
    t.index ["schema_id"], name: "index_d_form_element_possible_value_translations_schema_id"
  end

  create_table "dynamic_form_element_possible_values", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.uuid "schema_id", null: false
    t.uuid "form_id", null: false
    t.uuid "element_id", null: false
    t.text "value"
    t.integer "position", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.string "value_record_type"
    t.uuid "value_record_id"
    t.index ["deleted_at"], name: "index_dynamic_form_element_possible_values_on_deleted_at"
    t.index ["element_id"], name: "index_dynamic_form_element_possible_values_on_element_id"
    t.index ["form_id"], name: "index_dynamic_form_element_possible_values_on_form_id"
    t.index ["schema_id"], name: "index_dynamic_form_element_possible_values_on_schema_id"
    t.index ["value_record_type", "value_record_id"], name: "index_d_form_element_possible_values_value_record_type_and_id"
  end

  create_table "dynamic_form_element_translations", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.bigint "schema_id", null: false
    t.uuid "dynamic_form_element_id"
    t.string "label"
    t.text "text"
    t.text "help"
    t.string "watermark"
    t.text "translated_default_value"
    t.string "previous_button_text"
    t.string "next_button_text"
    t.string "cancel_button_text"
    t.string "submit_button_text"
    t.string "locale"
    t.string "save_as_draft_button_text"
    t.datetime "deleted_at", precision: nil
    t.index ["deleted_at"], name: "index_dynamic_form_element_translations_on_deleted_at"
    t.index ["dynamic_form_element_id"], name: "index_dynamic_form_translations_element_id"
    t.index ["schema_id"], name: "index_dynamic_form_element_translations_on_schema_id"
  end

  create_table "dynamic_form_elements", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.uuid "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.string "type"
    t.uuid "schema_id", null: false
    t.uuid "form_id", null: false
    t.integer "requirement", default: 0
    t.string "editor"
    t.integer "mode"
    t.integer "position"
    t.string "attribute_name"
    t.string "klass_name"
    t.text "target_klass_names"
    t.string "root_klass_name"
    t.text "method_names"
    t.uuid "schema_instance_id"
    t.boolean "show_label", default: true
    t.integer "value_position", default: 0
    t.boolean "show_value", default: true
    t.boolean "disabled", default: false
    t.boolean "read_only", default: false
    t.boolean "show_favorite", default: false
    t.boolean "favorite_never_disabled", default: false
    t.integer "autocomplete_mode", default: 0
    t.text "autocomplete_context"
    t.boolean "autocomplete_disable_elements", default: true
    t.boolean "can_autocomplete_value"
    t.uuid "parent_id"
    t.json "css_classes"
    t.string "col_size"
    t.string "label_col_size"
    t.string "input_col_size"
    t.boolean "show_previous_button", default: true
    t.boolean "show_next_button", default: true
    t.boolean "show_cancel_button", default: true
    t.boolean "show_submit_button", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.text "default_value"
    t.string "default_value_record_type"
    t.uuid "default_value_record_id"
    t.json "autocomplete_filters"
    t.integer "min"
    t.integer "max"
    t.json "errors_from"
    t.text "default_value_formula"
    t.uuid "same_as_id"
    t.json "condition_formula"
    t.string "sorting_attribute"
    t.string "sorting_type"
    t.integer "values_limit"
    t.boolean "show_save_as_draft_button", default: false
    t.boolean "force_default_value", default: false
    t.integer "record_type_for_default_value_formula"
    t.boolean "create_record_when_not_changed", default: false
    t.boolean "compact", default: false
    t.index ["default_value_record_type", "default_value_record_id"], name: "index_d_form_elements_default_value_record_type_and_id"
    t.index ["deleted_at"], name: "index_dynamic_form_elements_on_deleted_at"
    t.index ["form_id"], name: "index_dynamic_form_elements_on_form_id"
    t.index ["parent_id"], name: "index_dynamic_form_elements_on_parent_id"
    t.index ["schema_id"], name: "index_dynamic_form_elements_on_schema_id"
    t.index ["schema_instance_id"], name: "index_dynamic_form_elements_on_schema_instance_id"
    t.index ["uuid"], name: "index_dynamic_form_elements_on_uuid"
  end

  create_table "dynamic_form_schema_associations", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.string "type"
    t.uuid "schema_id", null: false
    t.uuid "form_id", null: false
    t.uuid "owner_instance_id"
    t.uuid "target_instance_id"
    t.string "klass_name"
    t.string "method_name"
    t.boolean "merge", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.index ["deleted_at"], name: "index_dynamic_form_schema_associations_on_deleted_at"
    t.index ["form_id"], name: "index_dynamic_form_schema_associations_on_form_id"
    t.index ["owner_instance_id"], name: "index_dynamic_form_schema_associations_on_owner_instance_id"
    t.index ["schema_id"], name: "index_dynamic_form_schema_associations_on_schema_id"
    t.index ["target_instance_id"], name: "index_dynamic_form_schema_associations_on_target_instance_id"
  end

  create_table "dynamic_form_schema_instances", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.uuid "schema_id", null: false
    t.uuid "form_id", null: false
    t.string "klass_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.index ["deleted_at"], name: "index_dynamic_form_schema_instances_on_deleted_at"
    t.index ["form_id"], name: "index_dynamic_form_schema_instances_on_form_id"
    t.index ["schema_id"], name: "index_dynamic_form_schema_instances_on_schema_id"
  end

  create_table "dynamic_form_submission_records", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.uuid "schema_id", null: false
    t.uuid "form_id", null: false
    t.uuid "submission_id", null: false
    t.uuid "schema_instance_id", null: false
    t.string "record_type"
    t.uuid "record_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.index ["deleted_at"], name: "index_dynamic_form_submission_records_on_deleted_at"
    t.index ["form_id"], name: "index_dynamic_form_submission_records_on_form_id"
    t.index ["record_type", "record_id"], name: "index_dynamic_form_submission_records_on_record_type_and_id"
    t.index ["schema_id"], name: "index_dynamic_form_submission_records_on_schema_id"
    t.index ["schema_instance_id"], name: "index_dynamic_form_submission_records_on_schema_instance_id"
    t.index ["submission_id"], name: "index_dynamic_form_submission_records_on_submission_id"
  end

  create_table "dynamic_form_submissions", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.uuid "schema_id", null: false
    t.uuid "form_id", null: false
    t.text "params"
    t.text "original_params"
    t.string "submitter_type"
    t.uuid "submitter_id"
    t.string "checker_type"
    t.uuid "checker_id"
    t.string "session_id"
    t.string "ip_address"
    t.string "user_agent"
    t.integer "state", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.string "source_record_type"
    t.uuid "source_record_id"
    t.string "target_record_type"
    t.uuid "target_record_id"
    t.text "submission_errors"
    t.string "batch_id"
    t.index ["batch_id"], name: "index_dynamic_form_submissions_on_batch_id"
    t.index ["checker_type", "checker_id", "form_id"], name: "index_dynamic_form_s_on_checker_type_and_id_and_form_id"
    t.index ["checker_type", "checker_id"], name: "index_dynamic_form_s_on_checker_type_and_id"
    t.index ["deleted_at"], name: "index_dynamic_form_submissions_on_deleted_at"
    t.index ["form_id"], name: "index_dynamic_form_submissions_on_form_id"
    t.index ["schema_id"], name: "index_dynamic_form_submissions_on_schema_id"
    t.index ["source_record_type", "source_record_id"], name: "index_dynamic_form_s_on_source_record_type_and_id"
    t.index ["submitter_type", "submitter_id", "form_id"], name: "index_dynamic_form_s_on_submitter_type_and_id_and_form_id"
    t.index ["submitter_type", "submitter_id"], name: "index_dynamic_form_s_on_submitter_type_and_id"
    t.index ["target_record_type", "target_record_id"], name: "index_dynamic_form_s_on_target_record_type_and_id"
  end

  create_table "dynamic_form_translations", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.uuid "schema_id", null: false
    t.uuid "dynamic_form_id"
    t.string "human_name"
    t.string "locale"
    t.text "text_before_start_date"
    t.text "text_after_end_date"
    t.datetime "deleted_at", precision: nil
    t.index ["deleted_at"], name: "index_dynamic_form_translations_on_deleted_at"
    t.index ["dynamic_form_id"], name: "index_dynamic_form_translations_id"
    t.index ["schema_id"], name: "index_dynamic_form_translations_on_schema_id"
  end

  create_table "dynamic_form_validation_rules", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.string "type"
    t.uuid "schema_id", null: false
    t.uuid "form_id", null: false
    t.text "element_ids"
    t.integer "requirement"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.index ["deleted_at"], name: "index_dynamic_form_validation_rules_on_deleted_at"
    t.index ["form_id"], name: "index_dynamic_form_validation_rules_on_form_id"
    t.index ["schema_id"], name: "index_dynamic_form_validation_rules_on_schema_id"
  end

  create_table "dynamic_forms", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.uuid "schema_id", null: false
    t.string "klass_name"
    t.string "association_klass_name"
    t.string "association_name"
    t.integer "actions"
    t.integer "mode", default: 0, null: false
    t.string "source_klass_name"
    t.string "target_klass_name"
    t.integer "column_count", default: 1
    t.boolean "hide_empty_inputs", default: false
    t.text "final_redirect_url"
    t.string "lang"
    t.boolean "auto_submission", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.boolean "default", default: false
    t.boolean "updated_when_schema_is_changed", default: false
    t.uuid "theme_id"
    t.datetime "start_date", precision: nil
    t.datetime "end_date", precision: nil
    t.boolean "async_submission", default: false
    t.boolean "evaluate_access_with_formula", default: false
    t.string "access_formula"
    t.string "access_formula_record_type"
    t.uuid "access_formula_record_id"
    t.text "on_load_script"
    t.string "purpose"
    t.index ["access_formula_record_type", "access_formula_record_id"], name: "index_dynamic_forms_on_access_formula_record_id"
    t.index ["deleted_at"], name: "index_dynamic_forms_on_deleted_at"
    t.index ["schema_id"], name: "index_dynamic_forms_on_schema_id"
    t.index ["source_klass_name"], name: "index_dynamic_forms_on_source_klass_name"
    t.index ["target_klass_name"], name: "index_dynamic_forms_on_target_klass_name"
    t.index ["theme_id"], name: "index_dynamic_forms_on_theme_id"
  end

  create_table "dynamic_import_columns", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.uuid "schema_id", null: false
    t.uuid "setting_id", null: false
    t.uuid "source_id", null: false
    t.integer "position"
    t.text "method_names", default: "--- []\n"
    t.text "path", default: "--- []\n"
    t.string "value_separator"
    t.boolean "only_foreign_not_deleted", default: true
    t.boolean "when_create", default: true
    t.boolean "when_update", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.index ["deleted_at"], name: "index_dynamic_import_columns_on_deleted_at"
    t.index ["schema_id"], name: "index_dynamic_import_columns_on_schema_id"
    t.index ["setting_id"], name: "index_dynamic_import_columns_on_setting_id"
    t.index ["source_id"], name: "index_dynamic_import_columns_on_source_id"
  end

  create_table "dynamic_import_jobs", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.string "type"
    t.uuid "schema_id", null: false
    t.uuid "setting_id", null: false
    t.uuid "parent_id"
    t.integer "current_line"
    t.integer "lines_to_process"
    t.integer "state", default: 0
    t.boolean "process_automatically", default: true
    t.uuid "source_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.index ["deleted_at"], name: "index_dynamic_import_jobs_on_deleted_at"
    t.index ["id", "type"], name: "index_dynamic_import_jobs_on_id_and_type"
    t.index ["parent_id"], name: "index_dynamic_import_jobs_on_parent_id"
    t.index ["schema_id"], name: "index_dynamic_import_jobs_on_schema_id"
    t.index ["setting_id"], name: "index_dynamic_import_jobs_on_setting_id"
    t.index ["source_id"], name: "index_dynamic_import_jobs_on_source_id"
  end

  create_table "dynamic_import_logs", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.string "type"
    t.uuid "schema_id", null: false
    t.uuid "setting_id", null: false
    t.uuid "job_id", null: false
    t.string "action"
    t.string "instance_type"
    t.uuid "instance_id"
    t.integer "line"
    t.text "messages"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.index ["deleted_at"], name: "index_dynamic_import_logs_on_deleted_at"
    t.index ["instance_type", "instance_id"], name: "index_dynamic_import_logs_on_instance_type_and_instance_id"
    t.index ["job_id"], name: "index_dynamic_import_logs_on_job_id"
    t.index ["schema_id"], name: "index_dynamic_import_logs_on_schema_id"
    t.index ["setting_id"], name: "index_dynamic_import_logs_on_setting_id"
  end

  create_table "dynamic_import_settings", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.string "name"
    t.uuid "schema_id", null: false
    t.string "klass_name"
    t.uuid "actor_id"
    t.boolean "async", default: true
    t.boolean "visible", default: true
    t.string "cron"
    t.integer "lines_to_process"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.index ["actor_id"], name: "index_dynamic_import_settings_on_actor_id"
    t.index ["deleted_at"], name: "index_dynamic_import_settings_on_deleted_at"
    t.index ["klass_name"], name: "index_dynamic_import_settings_on_klass_name"
    t.index ["schema_id"], name: "index_dynamic_import_settings_on_schema_id"
    t.index ["visible"], name: "index_dynamic_import_settings_on_visible"
  end

  create_table "dynamic_import_sources", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.string "name"
    t.string "type"
    t.uuid "schema_id", null: false
    t.uuid "setting_id", null: false
    t.string "klass_name"
    t.uuid "original_id"
    t.boolean "name_computed", default: false
    t.string "encoding"
    t.boolean "has_title_line", default: true
    t.string "column_delimiter", default: ";"
    t.string "line_delimiter", default: "auto"
    t.string "quote_char", default: "\""
    t.string "multi_list_value_separator"
    t.string "actions", default: "---\n- :create\n- :update\n"
    t.boolean "allow_remove", default: false
    t.boolean "add_possible_values", default: false
    t.boolean "accumulate_values", default: true
    t.boolean "only_not_deleted", default: true
    t.boolean "visible", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.boolean "liberal_parsing", default: false
    t.index ["deleted_at"], name: "index_dynamic_import_sources_on_deleted_at"
    t.index ["klass_name"], name: "index_dynamic_import_sources_on_klass_name"
    t.index ["original_id"], name: "index_dynamic_import_sources_on_original_id"
    t.index ["schema_id"], name: "index_dynamic_import_sources_on_schema_id"
    t.index ["setting_id"], name: "index_dynamic_import_sources_on_setting_id"
    t.index ["visible"], name: "index_dynamic_import_sources_on_visible"
  end

  create_table "dynamic_import_transformations", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.string "type"
    t.uuid "schema_id", null: false
    t.uuid "setting_id", null: false
    t.uuid "input_id"
    t.uuid "output_id"
    t.boolean "visible", default: true
    t.integer "position"
    t.string "input_encoding"
    t.string "output_encoding"
    t.string "formula"
    t.string "new_col_name"
    t.string "row_delimiters", default: "--- []\n"
    t.string "columns", default: "--- []\n"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.json "apply_errors", default: {}
    t.index ["deleted_at"], name: "index_dynamic_import_transformations_on_deleted_at"
    t.index ["input_id"], name: "index_dynamic_import_transformations_on_input_id"
    t.index ["output_id"], name: "index_dynamic_import_transformations_on_output_id"
    t.index ["schema_id"], name: "index_dynamic_import_transformations_on_schema_id"
    t.index ["setting_id"], name: "index_dynamic_import_transformations_on_setting_id"
    t.index ["visible"], name: "index_dynamic_import_transformations_on_visible"
  end

  create_table "dynamic_layout_elements", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.string "component"
    t.json "component_params", default: {}
    t.string "component_params_converter_type"
    t.json "component_params_converter_options", default: {}
    t.uuid "schema_id", null: false
    t.uuid "layout_id", null: false
    t.uuid "parent_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.integer "position"
    t.index ["deleted_at"], name: "index_dynamic_layout_elements_on_deleted_at"
    t.index ["layout_id"], name: "index_dynamic_layout_elements_on_layout_id"
    t.index ["parent_id"], name: "index_dynamic_layout_elements_on_parent_id"
    t.index ["schema_id"], name: "index_dynamic_layout_elements_on_schema_id"
  end

  create_table "dynamic_layout_translations", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.uuid "schema_id", null: false
    t.uuid "dynamic_layout_id"
    t.string "human_name"
    t.string "locale"
    t.index ["dynamic_layout_id"], name: "index_dynamic_layout_translations_id"
    t.index ["schema_id"], name: "index_dynamic_layout_translations_on_schema_id"
  end

  create_table "dynamic_layouts", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.uuid "schema_id", null: false
    t.string "klass_name"
    t.string "name"
    t.integer "actions"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.boolean "default", default: false
    t.boolean "updated_when_schema_is_changed", default: false
    t.string "mode"
    t.uuid "menu_item_id"
    t.string "purpose"
    t.index ["deleted_at"], name: "index_dynamic_layouts_on_deleted_at"
    t.index ["schema_id"], name: "index_dynamic_layouts_on_schema_id"
  end

  create_table "dynamic_redirections", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.string "name", null: false
    t.uuid "schema_id", null: false
    t.uuid "klass_id"
    t.boolean "enabled", default: true
    t.text "condition_type"
    t.json "condition_params", default: {}
    t.text "target_type", null: false
    t.uuid "target_klass_id"
    t.text "target_formula"
    t.json "target_params", default: {}
    t.text "fallback_type"
    t.uuid "fallback_klass_id"
    t.text "fallback_formula"
    t.json "fallback_params", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["fallback_klass_id"], name: "index_dynamic_redirections_on_fallback_klass_id"
    t.index ["klass_id"], name: "index_dynamic_redirections_on_klass_id"
    t.index ["schema_id"], name: "index_dynamic_redirections_on_schema_id"
    t.index ["target_klass_id"], name: "index_dynamic_redirections_on_target_klass_id"
  end

  create_table "dynamic_schema_association_translations", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.uuid "dynamic_schema_association_id"
    t.string "human_name"
    t.string "locale"
    t.uuid "schema_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_dynamic_schema_association_translations_on_deleted_at"
    t.index ["dynamic_schema_association_id"], name: "index_dynamic_schema_association_translations_association_id"
    t.index ["schema_id"], name: "index_dynamic_schema_association_translations_on_schema_id"
  end

  create_table "dynamic_schema_associations", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.string "name"
    t.uuid "schema_id", null: false
    t.uuid "target_klass_id"
    t.uuid "owner_klass_id"
    t.uuid "inverse_of_id"
    t.string "type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.string "formula"
    t.text "comment"
    t.boolean "dependent_destroy", default: false
    t.boolean "touch_target", default: false
    t.boolean "locked", default: false
    t.uuid "baseklass_id"
    t.json "default_elasticsearch_filters", default: {}
    t.uuid "through_id"
    t.json "default_elasticsearch_order", default: []
    t.integer "editor"
    t.json "default_value_record_refs", default: []
    t.index ["baseklass_id"], name: "index_dynamic_schema_associations_on_baseklass_id"
    t.index ["deleted_at"], name: "index_dynamic_schema_associations_on_deleted_at"
    t.index ["inverse_of_id"], name: "index_dynamic_schema_associations_on_inverse_id"
    t.index ["owner_klass_id"], name: "index_dynamic_schema_associations_on_owner_klass_id"
    t.index ["schema_id", "owner_klass_id", "name"], name: "uniq_index_dynamic_schema_associations", unique: true, where: "(deleted_at IS NULL)"
    t.index ["schema_id"], name: "index_dynamic_schema_associations_on_schema_id"
    t.index ["target_klass_id"], name: "index_dynamic_schema_associations_on_target_klass_id"
    t.index ["through_id"], name: "index_dynamic_schema_associations_on_through_id"
    t.index ["type"], name: "index_dynamic_schema_associations_on_type"
  end

  create_table "dynamic_schema_attachment_translations", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.uuid "dynamic_schema_attachment_id"
    t.string "human_name"
    t.string "locale"
    t.uuid "schema_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_dynamic_schema_attachment_translations_on_deleted_at"
    t.index ["dynamic_schema_attachment_id"], name: "index_dynamic_schema_attachment_translations_attachment_id"
    t.index ["schema_id"], name: "index_dynamic_schema_attachment_translations_on_schema_id"
  end

  create_table "dynamic_schema_attachment_variants", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.string "name", null: false
    t.integer "format"
    t.integer "quality"
    t.integer "resize_type"
    t.integer "resize_width"
    t.integer "resize_height"
    t.boolean "crop", default: false
    t.integer "crop_left"
    t.integer "crop_top"
    t.integer "crop_width"
    t.integer "crop_height"
    t.text "comment"
    t.uuid "schema_id", null: false
    t.uuid "attachment_id"
    t.string "type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.boolean "locked", default: false
    t.index ["attachment_id"], name: "index_dynamic_schema_attachment_variants_on_attachment_id"
    t.index ["deleted_at"], name: "index_dynamic_schema_attachment_variants_on_deleted_at"
    t.index ["schema_id", "attachment_id", "name"], name: "uniq_index_dynamic_schema_attachment_variants", unique: true, where: "(deleted_at IS NULL)"
    t.index ["schema_id"], name: "index_dynamic_schema_attachment_variants_on_schema_id"
    t.index ["type"], name: "index_dynamic_schema_attachment_variants_on_type"
  end

  create_table "dynamic_schema_attachments", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.string "name"
    t.uuid "schema_id", null: false
    t.uuid "owner_klass_id"
    t.string "type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.text "comment"
    t.string "formula"
    t.boolean "locked", default: false
    t.uuid "baseklass_id"
    t.json "extensions"
    t.float "size_limit"
    t.integer "editor"
    t.index ["baseklass_id"], name: "index_dynamic_schema_attachments_on_baseklass_id"
    t.index ["deleted_at"], name: "index_dynamic_schema_attachments_on_deleted_at"
    t.index ["owner_klass_id"], name: "index_dynamic_schema_attachments_on_owner_klass_id"
    t.index ["schema_id", "owner_klass_id", "name"], name: "uniq_index_dynamic_schema_attachments", unique: true, where: "(deleted_at IS NULL)"
    t.index ["schema_id"], name: "index_dynamic_schema_attachments_on_schema_id"
    t.index ["type"], name: "index_dynamic_schema_attachments_on_type"
  end

  create_table "dynamic_schema_attribute_enum_value_translations", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.uuid "schema_id", null: false
    t.uuid "dynamic_schema_attribute_enum_value_id"
    t.string "human_name"
    t.string "locale"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_dynamic_schema_attribute_enum_value_translations"
    t.index ["dynamic_schema_attribute_enum_value_id"], name: "index_dynamic_schema_attribute_enum_value_id"
    t.index ["schema_id"], name: "index_dynamic_schema_attr_enum_value_tr_schema_id"
  end

  create_table "dynamic_schema_attribute_enum_values", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.uuid "uuid", null: false
    t.string "name"
    t.uuid "schema_id", null: false
    t.uuid "attr_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.text "comment"
    t.boolean "locked", default: false
    t.index ["attr_id"], name: "index_dynamic_schema_attribute_enum_values_on_attr_id"
    t.index ["deleted_at"], name: "index_dynamic_schema_attribute_enum_values_on_deleted_at"
    t.index ["schema_id"], name: "index_dynamic_schema_attribute_enum_values_on_schema_id"
  end

  create_table "dynamic_schema_attribute_translations", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.uuid "dynamic_schema_attribute_id"
    t.string "human_name"
    t.string "locale"
    t.uuid "schema_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_dynamic_schema_attribute_translations_on_deleted_at"
    t.index ["dynamic_schema_attribute_id"], name: "index_dynamic_schema_attribute_translations_attribute_id"
    t.index ["schema_id"], name: "index_dynamic_schema_attribute_translations_on_schema_id"
  end

  create_table "dynamic_schema_attributes", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.string "name"
    t.integer "column"
    t.uuid "schema_id", null: false
    t.uuid "klass_id"
    t.uuid "baseklass_id"
    t.boolean "index", default: false
    t.string "type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.string "formula"
    t.text "comment"
    t.integer "protocols", default: 0
    t.boolean "incremental", default: false
    t.integer "format"
    t.boolean "locked", default: false
    t.json "format_options", default: {}
    t.integer "editor"
    t.json "default_value"
    t.index ["baseklass_id"], name: "index_dynamic_schema_attributes_on_baseklass_id"
    t.index ["deleted_at"], name: "index_dynamic_schema_attributes_on_deleted_at"
    t.index ["klass_id"], name: "index_dynamic_schema_attributes_on_klass_id"
    t.index ["schema_id", "klass_id", "name"], name: "uniq_index_dynamic_schema_attributes", unique: true, where: "(deleted_at IS NULL)"
    t.index ["schema_id"], name: "index_dynamic_schema_attributes_on_schema_id"
    t.index ["type"], name: "index_dynamic_schema_attributes_on_type"
  end

  create_table "dynamic_schema_concern_translations", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.uuid "dynamic_schema_concern_id"
    t.string "human_name"
    t.string "locale"
    t.uuid "schema_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_dynamic_schema_concern_translations_on_deleted_at"
    t.index ["dynamic_schema_concern_id"], name: "index_dynamic_schema_concern_translations_concern_id"
    t.index ["schema_id"], name: "index_dynamic_schema_concern_translations_on_schema_id"
  end

  create_table "dynamic_schema_concerns", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.string "name"
    t.uuid "schema_id", null: false
    t.uuid "klass_id"
    t.uuid "feature_id"
    t.string "type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.text "comment"
    t.boolean "template", default: false
    t.boolean "locked", default: false
    t.index ["deleted_at"], name: "index_dynamic_schema_concerns_on_deleted_at"
    t.index ["feature_id"], name: "index_dynamic_schema_concerns_on_feature_id"
    t.index ["klass_id"], name: "index_dynamic_schema_concerns_on_klass_id"
    t.index ["schema_id", "klass_id", "feature_id", "name"], name: "uniq_index_dynamic_schema_concerns", unique: true, where: "(deleted_at IS NULL)"
    t.index ["schema_id"], name: "index_dynamic_schema_concerns_on_schema_id"
    t.index ["type"], name: "index_dynamic_schema_concerns_on_type"
  end

  create_table "dynamic_schema_feature_translations", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.uuid "dynamic_schema_feature_id"
    t.string "human_name"
    t.string "locale"
    t.uuid "schema_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_dynamic_schema_feature_translations_on_deleted_at"
    t.index ["dynamic_schema_feature_id"], name: "index_dynamic_schema_feature_translations_feature_id"
    t.index ["schema_id"], name: "index_dynamic_schema_feature_translations_on_schema_id"
  end

  create_table "dynamic_schema_features", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.string "name"
    t.uuid "schema_id", null: false
    t.boolean "enabled", default: true
    t.boolean "visible", default: true
    t.boolean "mandatory", default: false
    t.integer "dependency_order"
    t.string "type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.text "comment"
    t.boolean "locked", default: false
    t.index ["deleted_at"], name: "index_dynamic_schema_features_on_deleted_at"
    t.index ["schema_id", "name"], name: "uniq_index_dynamic_schema_features", unique: true, where: "(deleted_at IS NULL)"
    t.index ["schema_id"], name: "index_dynamic_schema_features_on_schema_id"
    t.index ["type"], name: "index_dynamic_schema_features_on_type"
  end

  create_table "dynamic_schema_klass_translations", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.uuid "schema_id", null: false
    t.uuid "dynamic_schema_klass_id"
    t.string "human_name"
    t.string "locale"
    t.string "plural_human_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_dynamic_schema_klass_translations_on_deleted_at"
    t.index ["dynamic_schema_klass_id"], name: "index_dynamic_schema_klass_translations_klass_id"
    t.index ["schema_id"], name: "index_dynamic_schema_klass_translations_on_schema_id"
  end

  create_table "dynamic_schema_klasses", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.string "permalink"
    t.string "name"
    t.string "const_table_name"
    t.string "original_const_table_name"
    t.uuid "schema_id", null: false
    t.uuid "superklass_id"
    t.uuid "baseklass_id"
    t.integer "depth"
    t.boolean "versioned", default: true
    t.integer "table_profile", default: 20
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.json "options_for_indexed_json", default: {}
    t.json "elasticsearch_mapping", default: {}
    t.datetime "elasticsearch_updated_at", precision: nil
    t.string "icon"
    t.uuid "name_attribute_id"
    t.uuid "photo_attachment_id"
    t.text "comment"
    t.string "route_key", null: false
    t.boolean "frozen_table", default: false
    t.json "global_search_fields", default: []
    t.json "dependencies_from_formulas", default: {}
    t.json "json", default: {}
    t.boolean "locked", default: false
    t.index ["baseklass_id"], name: "index_dynamic_schema_klasses_on_baseklass_id"
    t.index ["deleted_at"], name: "index_dynamic_schema_klasses_on_deleted_at"
    t.index ["name_attribute_id"], name: "index_dynamic_schema_klasses_on_name_attribute_id"
    t.index ["permalink"], name: "index_dynamic_schema_klasses_on_permalink"
    t.index ["photo_attachment_id"], name: "index_dynamic_schema_klasses_on_photo_attachment_id"
    t.index ["schema_id", "name"], name: "uniq_index_dynamic_schema_klasses", unique: true, where: "(deleted_at IS NULL)"
    t.index ["schema_id", "route_key"], name: "uniq_index_dynamic_schema_klasses_route_key", unique: true, where: "(deleted_at IS NULL)"
    t.index ["schema_id"], name: "index_dynamic_schema_klasses_on_schema_id"
    t.index ["superklass_id"], name: "index_dynamic_schema_klasses_on_superklass_id"
  end

  create_table "dynamic_schema_migration_translations", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.uuid "dynamic_schema_migration_id"
    t.string "human_name"
    t.string "locale"
    t.uuid "schema_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_dynamic_schema_migration_translations_on_deleted_at"
    t.index ["dynamic_schema_migration_id"], name: "index_dynamic_schema_migration_translations_id"
    t.index ["schema_id"], name: "index_dynamic_schema_migration_translations_on_schema_id"
  end

  create_table "dynamic_schema_migrations", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.string "name"
    t.integer "state", default: 0
    t.integer "progress", default: 0
    t.integer "total", default: 1
    t.uuid "schema_id", null: false
    t.uuid "klass_id"
    t.uuid "attr_id"
    t.string "source_attribute_type"
    t.integer "source_attribute_column"
    t.boolean "source_attribute_index"
    t.string "target_attribute_type"
    t.integer "target_attribute_column"
    t.boolean "target_attribute_index"
    t.string "type"
    t.datetime "started_at", precision: nil
    t.datetime "finished_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.text "comment"
    t.index ["attr_id"], name: "index_dynamic_schema_migrations_on_attr_id"
    t.index ["deleted_at"], name: "index_dynamic_schema_migrations_on_deleted_at"
    t.index ["klass_id"], name: "index_dynamic_schema_migrations_on_klass_id"
    t.index ["schema_id"], name: "index_dynamic_schema_migrations_on_schema_id"
    t.index ["state"], name: "index_dynamic_schema_migrations_on_state"
    t.index ["type"], name: "index_dynamic_schema_migrations_on_type"
  end

  create_table "dynamic_schema_normalization_translations", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.uuid "schema_id", null: false
    t.uuid "dynamic_schema_normalization_id"
    t.string "human_name"
    t.string "locale"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_dynamic_schema_normalization_translations_on_deleted_at"
    t.index ["dynamic_schema_normalization_id"], name: "index_dynamic_schema_normalization_translations_attribute_id"
    t.index ["schema_id"], name: "index_dynamic_schema_normalization_translations_on_schema_id"
  end

  create_table "dynamic_schema_normalizations", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.string "type"
    t.json "options"
    t.uuid "schema_id", null: false
    t.uuid "klass_id"
    t.uuid "attr_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.boolean "locked", default: false
    t.index ["attr_id"], name: "index_dynamic_schema_normalizations_on_attr_id"
    t.index ["deleted_at"], name: "index_dynamic_schema_normalizations_on_deleted_at"
    t.index ["klass_id"], name: "index_dynamic_schema_normalizations_on_klass_id"
    t.index ["schema_id", "klass_id", "attr_id"], name: "index_dynamic_schema_normalizations", where: "(deleted_at IS NULL)"
    t.index ["schema_id"], name: "index_dynamic_schema_normalizations_on_schema_id"
    t.index ["type"], name: "index_dynamic_schema_normalizations_on_type"
  end

  create_table "dynamic_schema_option_translations", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.uuid "dynamic_schema_option_id"
    t.string "human_name"
    t.string "locale"
    t.uuid "schema_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_dynamic_schema_option_translations_on_deleted_at"
    t.index ["dynamic_schema_option_id"], name: "dynamic_schema_option_translations_id"
    t.index ["schema_id"], name: "index_dynamic_schema_option_translations_on_schema_id"
  end

  create_table "dynamic_schema_options", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.uuid "schema_id", null: false
    t.string "owner_type", null: false
    t.uuid "owner_id", null: false
    t.string "value_string"
    t.json "value_json"
    t.integer "value_integer"
    t.boolean "value_boolean"
    t.float "value_float"
    t.text "value_text"
    t.string "name"
    t.boolean "visible", default: true
    t.string "type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.string "coder_type"
    t.boolean "global", default: true
    t.boolean "locked", default: false
    t.index ["deleted_at"], name: "index_dynamic_schema_options_on_deleted_at"
    t.index ["owner_type", "owner_id"], name: "index_dynamic_schema_options_owner"
    t.index ["schema_id"], name: "index_dynamic_schema_options_on_schema_id"
  end

  create_table "dynamic_schema_reserved_tables", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.string "klass_name", null: false
    t.string "table_name", null: false
    t.uuid "schema_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_dynamic_schema_reserved_tables_on_deleted_at"
    t.index ["klass_name"], name: "index_dynamic_schema_reserved_tables_on_klass_name"
    t.index ["schema_id"], name: "index_dynamic_schema_reserved_tables_on_schema_id"
  end

  create_table "dynamic_schema_sequence_translations", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.uuid "schema_id", null: false
    t.uuid "dynamic_schema_sequence_id"
    t.string "human_name"
    t.string "locale"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.index ["deleted_at"], name: "index_dynamic_schema_seq_translations_deleted_at_id"
    t.index ["dynamic_schema_sequence_id"], name: "index_dynamic_schema_seq_translations_attribute_id"
    t.index ["schema_id"], name: "index_dynamic_schema_seq_translations_schema_id"
  end

  create_table "dynamic_schema_sequences", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.uuid "schema_id", null: false
    t.uuid "attr_id", null: false
    t.uuid "condition_attr_id"
    t.uuid "condition_value_id"
    t.string "name"
    t.string "const_sequence_name"
    t.string "original_const_sequence_name"
    t.integer "start_value", default: 1
    t.string "prefix", default: ""
    t.string "suffix", default: ""
    t.integer "part1_type", default: 0
    t.integer "part1_length", default: 1
    t.integer "part2_type", default: 0
    t.integer "part2_length", default: 0
    t.integer "part3_type", default: 0
    t.integer "part3_length", default: 0
    t.text "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.boolean "locked", default: false
    t.uuid "condition_klass_id"
    t.integer "condition_type", default: 0
    t.index ["attr_id"], name: "index_dynamic_schema_sequences_on_attr_id"
    t.index ["condition_attr_id"], name: "index_dynamic_schema_sequences_condition_attr_id"
    t.index ["condition_klass_id"], name: "index_dynamic_schema_sequences_condition_klass_id"
    t.index ["condition_value_id"], name: "index_dynamic_schema_sequences_condition_value_id"
    t.index ["deleted_at"], name: "index_dynamic_schema_sequences_on_deleted_at"
    t.index ["schema_id"], name: "index_dynamic_schema_sequences_on_schema_id"
  end

  create_table "dynamic_schema_translations", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.uuid "schema_id", null: false
    t.string "human_name"
    t.string "locale"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_dynamic_schema_translations_on_deleted_at"
    t.index ["schema_id"], name: "index_dynamic_schema_translations_on_schema_id"
  end

  create_table "dynamic_schema_validation_attributes", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.uuid "schema_id", null: false
    t.uuid "validation_id", null: false
    t.uuid "attr_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.index ["attr_id"], name: "index_dynamic_schema_validation_attributes_on_attr_id"
    t.index ["deleted_at"], name: "index_dynamic_schema_validation_attributes_on_deleted_at"
    t.index ["schema_id"], name: "index_dynamic_schema_validation_attributes_on_schema_id"
    t.index ["validation_id", "attr_id"], name: "index_dynamic_schema_validation_attributes", where: "(deleted_at IS NULL)"
    t.index ["validation_id"], name: "index_dynamic_schema_validation_attributes_on_validation_id"
  end

  create_table "dynamic_schema_validation_translations", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.uuid "schema_id", null: false
    t.uuid "dynamic_schema_validation_id"
    t.string "human_name"
    t.string "locale"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.index ["deleted_at"], name: "index_dynamic_schema_validation_translations_on_deleted_at"
    t.index ["dynamic_schema_validation_id"], name: "index_dynamic_schema_validation_translations_attribute_id"
    t.index ["schema_id"], name: "index_dynamic_schema_validation_translations_on_schema_id"
  end

  create_table "dynamic_schema_validations", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.string "name"
    t.string "type"
    t.string "expression"
    t.string "operator"
    t.string "comparison_value"
    t.uuid "schema_id", null: false
    t.uuid "klass_id"
    t.uuid "attr_id"
    t.uuid "comparison_attr_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.text "comment"
    t.boolean "locked", default: false
    t.index ["attr_id"], name: "index_dynamic_schema_validations_on_attr_id"
    t.index ["comparison_attr_id"], name: "index_dynamic_schema_validations_on_comparison_attr_id"
    t.index ["deleted_at"], name: "index_dynamic_schema_validations_on_deleted_at"
    t.index ["expression"], name: "index_dynamic_schema_validations_on_expression"
    t.index ["klass_id"], name: "index_dynamic_schema_validations_on_klass_id"
    t.index ["schema_id", "klass_id", "attr_id"], name: "index_dynamic_schema_validations", where: "(deleted_at IS NULL)"
    t.index ["schema_id"], name: "index_dynamic_schema_validations_on_schema_id"
    t.index ["type"], name: "index_dynamic_schema_validations_on_type"
  end

  create_table "dynamic_schemas", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.text "comment"
    t.string "permalink", null: false
    t.boolean "locked", default: false
    t.index ["deleted_at"], name: "index_dynamic_schemas_on_deleted_at"
    t.index ["name"], name: "uniq_index_dynamic_schemas", unique: true, where: "(deleted_at IS NULL)"
  end

  create_table "dynamic_theme_translations", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.uuid "schema_id", null: false
    t.uuid "dynamic_theme_id"
    t.string "human_name"
    t.string "locale"
    t.index ["dynamic_theme_id"], name: "index_dynamic_theme_tr_theme_id"
    t.index ["schema_id"], name: "index_dynamic_theme_tr_schema_id"
  end

  create_table "dynamic_themes", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.string "name", null: false
    t.uuid "schema_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.boolean "community_appearance", default: false
    t.index ["deleted_at"], name: "index_dynamic_themes_on_deleted_at"
    t.index ["schema_id", "name"], name: "uniq_index_dynamic_themes", unique: true, where: "(deleted_at IS NULL)"
    t.index ["schema_id"], name: "index_dynamic_themes_on_schema_id"
  end

  create_table "external_source_translations", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.uuid "external_source_id"
    t.string "human_name"
    t.string "locale"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_source_id"], name: "index_external_source_translations_on_external_source_id"
  end

  create_table "external_sources", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.text "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "memberships", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.uuid "community_id", null: false
    t.uuid "user_id", null: false
    t.integer "status", default: 0, null: false
    t.boolean "admin", default: false, null: false
    t.uuid "uneek_sso_uuid"
    t.string "uneek_sso_syncable_fingerprint"
    t.string "uneek_sso_client_syncable_fingerprint"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["community_id", "user_id"], name: "index_memberships_on_community_id_and_user_id", unique: true
    t.index ["uneek_sso_uuid"], name: "index_memberships_on_uneek_sso_uuid", unique: true
    t.index ["user_id"], name: "index_memberships_on_user_id"
  end

  create_table "role_context_field_translations", force: :cascade do |t|
    t.uuid "role_context_field_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "human_name"
    t.index ["locale"], name: "index_role_context_field_translations_on_locale"
    t.index ["role_context_field_id"], name: "index_role_context_field_translations_on_role_context_field_id"
  end

  create_table "role_context_fields", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.uuid "role_id", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "uneek_sso_uuid"
    t.string "uneek_sso_syncable_fingerprint"
    t.string "uneek_sso_client_syncable_fingerprint"
    t.index ["role_id", "name"], name: "index_role_context_fields_on_role_id_and_name", unique: true
  end

  create_table "role_translations", force: :cascade do |t|
    t.uuid "role_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "human_name"
    t.index ["locale"], name: "index_role_translations_on_locale"
    t.index ["role_id"], name: "index_role_translations_on_role_id"
  end

  create_table "roles", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.string "name", null: false
    t.uuid "community_id", null: false
    t.boolean "default", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "uneek_sso_uuid"
    t.string "uneek_sso_syncable_fingerprint"
    t.string "uneek_sso_client_syncable_fingerprint"
    t.boolean "admin", default: false, null: false
    t.index ["community_id", "name"], name: "index_roles_on_community_id_and_name", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "tools", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.uuid "community_id", null: false
    t.string "name", null: false
    t.string "application_name", null: false
    t.string "uri", null: false
    t.uuid "uneek_sso_uuid"
    t.string "uneek_sso_syncable_fingerprint"
    t.string "uneek_sso_client_syncable_fingerprint"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["community_id", "name"], name: "index_tools_on_community_id_and_name", unique: true
    t.index ["uneek_sso_uuid"], name: "index_tools_on_uneek_sso_uuid", unique: true
  end

  create_table "uneek_doc_gen_merge_files", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.string "type", null: false
    t.uuid "template_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "position", null: false
    t.uuid "object_template_id"
    t.text "attribute_path", default: "--- []\n"
    t.index ["object_template_id"], name: "index_uneek_doc_gen_merge_files_on_object_template_id"
    t.index ["template_id", "object_template_id"], name: "index_uneek_doc_gen_files_object_template_id_uq", unique: true
    t.index ["template_id", "position"], name: "index_uneek_doc_gen_merge_files_on_template_id_and_position", unique: true
    t.index ["type"], name: "index_uneek_doc_gen_merge_files_on_type"
  end

  create_table "uneek_doc_gen_templates", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.string "type", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "version", null: false
    t.string "class_name", null: false
    t.boolean "multiple", default: false, null: false
    t.uuid "wrapped_template_id"
    t.string "wrapped_format"
    t.string "default_attachment"
    t.string "output_name_formula"
    t.string "output_locale"
    t.index ["class_name"], name: "index_uneek_doc_gen_templates_on_class_name"
    t.index ["type"], name: "index_uneek_doc_gen_templates_on_type"
    t.index ["wrapped_template_id"], name: "index_uneek_doc_gen_templates_on_wrapped_template_id"
  end

  create_table "uneek_permission_domains", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.string "expression_method"
    t.string "expression_value"
    t.integer "expression_value_type"
    t.string "user_field"
    t.string "instance_field", null: false
    t.string "context_field"
    t.index ["instance_field", "context_field"], name: "uneek_permission_domains_uq", unique: true, where: "((expression_method IS NULL) AND (expression_value IS NULL) AND (user_field IS NULL))"
    t.index ["instance_field", "expression_method", "expression_value"], name: "uneek_permission_domains_expresion_uq", unique: true
    t.index ["instance_field", "user_field"], name: "uneek_permission_domains_user_uq", unique: true
    t.check_constraint "context_field IS NULL OR user_field IS NULL OR expression_method IS NULL AND expression_value IS NULL", name: "user_field_or_expression"
  end

  create_table "uneek_permission_manifests", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "community_id"
    t.index ["community_id"], name: "index_uneek_permission_manifests_on_community_id"
    t.index ["name"], name: "uneek_permission_manifests_uq", unique: true
  end

  create_table "uneek_permission_predefined_receivers", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.string "name"
    t.string "type"
    t.index ["type"], name: "uneek_predefined_receiver_uq", unique: true
  end

  create_table "uneek_permission_rules", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.uuid "domain_id"
    t.string "klass_name", null: false
    t.string "instance_type"
    t.uuid "instance_id"
    t.string "receiver_type", null: false
    t.uuid "receiver_id", null: false
    t.string "attr"
    t.integer "grant", null: false
    t.uuid "schema_id"
    t.uuid "manifest_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["attr"], name: "index_uneek_permission_rules_on_attr"
    t.index ["domain_id"], name: "index_uneek_permission_rules_on_domain_id"
    t.index ["grant"], name: "index_uneek_permission_rules_on_grant"
    t.index ["instance_type", "instance_id"], name: "index_uneek_permission_rules_on_instance_type_and_instance_id"
    t.index ["klass_name", "instance_id", "instance_type", "receiver_id", "receiver_type", "attr", "domain_id"], name: "uneek_permission_domain_uq", unique: true, where: "((domain_id IS NOT NULL) AND (attr IS NOT NULL) AND (instance_id IS NOT NULL) AND (instance_type IS NOT NULL))"
    t.index ["klass_name", "instance_id", "instance_type", "receiver_id", "receiver_type", "attr"], name: "uneek_permission_uq", unique: true, where: "((domain_id IS NULL) AND (attr IS NOT NULL) AND (instance_id IS NOT NULL) AND (instance_type IS NOT NULL))"
    t.index ["klass_name", "instance_id", "instance_type", "receiver_id", "receiver_type", "domain_id"], name: "uneek_permission_klass_instance_domain_uq", unique: true, where: "((domain_id IS NOT NULL) AND (attr IS NULL) AND (instance_id IS NOT NULL) AND (instance_type IS NOT NULL))"
    t.index ["klass_name", "instance_id", "instance_type", "receiver_id", "receiver_type"], name: "uneek_permission_klass_instance_uq", unique: true, where: "((domain_id IS NULL) AND (attr IS NULL) AND (instance_id IS NOT NULL) AND (instance_type IS NOT NULL))"
    t.index ["klass_name", "receiver_id", "receiver_type", "attr", "domain_id"], name: "uneek_permission_klass_attr_domain_uq", unique: true, where: "((domain_id IS NOT NULL) AND (instance_id IS NULL) AND (instance_type IS NULL) AND (attr IS NOT NULL))"
    t.index ["klass_name", "receiver_id", "receiver_type", "attr"], name: "uneek_permission_klass_attr_uq", unique: true, where: "((domain_id IS NULL) AND (instance_id IS NULL) AND (instance_type IS NULL) AND (attr IS NOT NULL))"
    t.index ["klass_name", "receiver_id", "receiver_type", "domain_id"], name: "uneek_permission_klass_domain_uq", unique: true, where: "((domain_id IS NOT NULL) AND (instance_id IS NULL) AND (instance_type IS NULL) AND (attr IS NULL))"
    t.index ["klass_name", "receiver_id", "receiver_type"], name: "uneek_permission_klass_uq", unique: true, where: "((domain_id IS NULL) AND (instance_id IS NULL) AND (instance_type IS NULL) AND (attr IS NULL))"
    t.index ["klass_name"], name: "index_uneek_permission_rules_on_klass_name"
    t.index ["manifest_id"], name: "index_uneek_permission_rules_on_manifest_id"
    t.index ["receiver_type", "receiver_id"], name: "index_uneek_permission_rules_on_receiver_type_and_receiver_id"
    t.index ["schema_id"], name: "index_uneek_permission_rules_on_schema_id"
  end

  create_table "user_role_domain_contexts", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.uuid "user_role_id", null: false
    t.string "field_name", null: false
    t.text "value", default: [], null: false, array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "uneek_sso_uuid"
    t.string "uneek_sso_syncable_fingerprint"
    t.string "uneek_sso_client_syncable_fingerprint"
    t.index ["user_role_id", "field_name"], name: "index_user_role_domain_contexts_on_user_role_id_and_field_name", unique: true
  end

  create_table "user_roles", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "role_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "uneek_sso_uuid"
    t.string "uneek_sso_syncable_fingerprint"
    t.string "uneek_sso_client_syncable_fingerprint"
    t.index ["role_id"], name: "index_user_roles_on_role_id"
    t.index ["user_id", "role_id"], name: "user_roles_uq", unique: true
  end

  create_table "user_tools", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "tool_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tool_id"], name: "index_user_tools_on_tool_id"
    t.index ["user_id", "tool_id"], name: "index_user_tools_on_user_id_and_tool_id", unique: true
  end

  create_table "users", id: :uuid, default: -> { "uuid_generate_v7()" }, force: :cascade do |t|
    t.uuid "uneek_sso_uuid"
    t.string "login", null: false
    t.string "email", null: false
    t.string "first_name"
    t.string "last_name"
    t.boolean "super_admin", default: false, null: false
    t.string "language"
    t.string "uneek_sso_syncable_fingerprint"
    t.string "uneek_sso_client_syncable_fingerprint"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "has_photo", default: false, null: false
    t.index ["login"], name: "index_users_on_login", unique: true
    t.index ["uneek_sso_uuid"], name: "index_users_on_uneek_sso_uuid", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "communities", "communities", column: "parent_id"
  add_foreign_key "communities", "dynamic_schemas", column: "schema_id"
  add_foreign_key "memberships", "communities"
  add_foreign_key "memberships", "users"
  add_foreign_key "role_context_fields", "roles"
  add_foreign_key "roles", "communities"
  add_foreign_key "tools", "communities"
  add_foreign_key "uneek_doc_gen_merge_files", "uneek_doc_gen_templates", column: "object_template_id"
  add_foreign_key "uneek_doc_gen_merge_files", "uneek_doc_gen_templates", column: "template_id"
  add_foreign_key "uneek_doc_gen_templates", "uneek_doc_gen_templates", column: "wrapped_template_id"
  add_foreign_key "user_role_domain_contexts", "user_roles"
  add_foreign_key "user_roles", "roles"
  add_foreign_key "user_roles", "users"
  add_foreign_key "user_tools", "tools"
  add_foreign_key "user_tools", "users"
end
