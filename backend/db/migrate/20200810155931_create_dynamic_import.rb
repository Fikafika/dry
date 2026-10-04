class CreateDynamicImport < ActiveRecord::Migration[6.0]

  def change
    create_table :dynamic_import_settings, id: :uuid do |t|
      t.string :name

      t.belongs_to :schema, index: true, type: :uuid, null: false
      t.string :klass_name, index: true

      t.belongs_to :actor, type: :uuid

      t.boolean :async, default: true

      t.boolean :visible, default: true, index: true
      t.string :cron
      t.integer :lines_to_process

      t.timestamps
      t.datetime :deleted_at, index: true
    end

    create_table :dynamic_import_sources, id: :uuid do |t|
      t.string :name
      t.string :type

      t.belongs_to :schema, index: true, type: :uuid, null: false
      t.belongs_to :setting, index: true, type: :uuid, null: false
      t.string :klass_name, index: true

      t.belongs_to :original, type: :uuid

      t.boolean :name_computed, default: false

      t.string :encoding

      t.boolean :has_title_line, default: true
      t.string :column_delimiter, default: ';'
      t.string :line_delimiter, default: :auto
      t.string :quote_char, default: '"'
      t.string :multi_list_value_separator

      t.string :actions, default: [:create, :update].to_yaml

      t.boolean :allow_remove, default: false
      t.boolean :add_possible_values, default: false
      t.boolean :accumulate_values, default: true
      t.boolean :only_not_deleted, default: true

      t.boolean :visible, default: true, index: true

      t.timestamps
      t.datetime :deleted_at, index: true
    end

    create_table :dynamic_import_transformations, id: :uuid do |t|
      t.string :type

      t.belongs_to :schema, index: true, type: :uuid, null: false
      t.belongs_to :setting, index: true, type: :uuid, null: false

      t.belongs_to :input, index: true, type: :uuid
      t.belongs_to :output, index: true, type: :uuid

      t.boolean :visible, default: true, index: true

      t.integer :position

      t.string :input_encoding
      t.string :output_encoding
      t.string :formula
      t.string :new_col_name

      t.string :row_delimiters, default: [].to_yaml
      t.string :columns, default: [].to_yaml

      t.timestamps
      t.datetime :deleted_at, index: true
    end

    create_table :dynamic_import_columns, id: :uuid do |t|
      t.belongs_to :schema, index: true, type: :uuid, null: false
      t.belongs_to :setting, index: true, type: :uuid, null: false
      t.belongs_to :source, index: true, type: :uuid, null: false

      t.integer :position

      t.text :method_names, default: [].to_yaml
      t.text :path, default: [].to_yaml

      t.string :value_separator
      t.boolean :only_foreign_not_deleted, default: true

      t.boolean :when_create, default: true
      t.boolean :when_update, default: true

      t.timestamps
      t.datetime :deleted_at, index: true
    end

    create_table :dynamic_import_jobs, id: :uuid do |t|
      t.string :type

      t.belongs_to :schema, index: true, type: :uuid, null: false
      t.belongs_to :setting, index: true, type: :uuid, null: false
      t.belongs_to :parent, type: :uuid

      t.integer :current_line
      t.integer :lines_to_process
      t.integer :state, default: 0 # pending
      t.boolean :process_automatically, default: true

      t.belongs_to :source, type: :uuid

      t.timestamps
      t.datetime :deleted_at, index: true
    end

    add_index :dynamic_import_jobs, [:id, :type]

    create_table :dynamic_import_logs, id: :uuid do |t|
      t.string :type

      t.belongs_to :schema, index: true, type: :uuid, null: false
      t.belongs_to :setting, index: true, type: :uuid, null: false
      t.belongs_to :job, type: :uuid, null: false

      t.string :action

      t.belongs_to :instance, polymorphic: true, type: :uuid
      t.integer :line
      t.text :messages

      t.timestamps
      t.datetime :deleted_at, index: true
    end

  end

end
