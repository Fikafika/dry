class CreateDynamicBuilder < ActiveRecord::Migration[6.0]
  def change
    create_table :dynamic_builders, id: :uuid do |t|
      t.belongs_to :schema, type: :uuid
      t.belongs_to :owner, polymorphic: true, type: :uuid
      t.text :klass_name
      t.timestamps
      t.datetime :deleted_at, index: true
    end

    create_table :dynamic_builder_nodes, id: :uuid do |t|
      t.belongs_to :schema, type: :uuid
      t.belongs_to :builder, type: :uuid
      t.text :klass_name
      t.timestamps
      t.datetime :deleted_at, index: true
    end

    create_table :dynamic_builder_edges, id: :uuid do |t|
      t.belongs_to :schema, type: :uuid
      t.belongs_to :builder, type: :uuid

      t.text :klass_name
      t.text :association_name

      t.belongs_to :source_node, type: :uuid
      t.belongs_to :target_node, type: :uuid
      t.timestamps
      t.datetime :deleted_at, index: true
    end

    create_table :dynamic_builder_options, id: :uuid do |t|
      t.belongs_to :schema, type: :uuid
      t.belongs_to :builder, type: :uuid
      t.belongs_to :node, type: :uuid

      t.text :method_name

      t.boolean :when_create, default: true
      t.boolean :when_update, default: true
      t.boolean :when_destroy, default: false

      t.timestamps
      t.datetime :deleted_at, index: true
    end
  end
end
