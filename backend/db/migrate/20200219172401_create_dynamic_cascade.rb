class CreateDynamicCascade < ActiveRecord::Migration[6.0]

  def change
    create_table :dynamic_cascades, id: :uuid do |t|
      t.belongs_to :owner, type: :uuid, polymorphic: true
      t.belongs_to :schema, type: :uuid
      t.belongs_to :klass, type: :uuid
      t.belongs_to :assoc, type: :uuid
      t.datetime :updated_at
      t.datetime :deleted_at, index: true
      t.string :type

      t.index [:owner_id, :owner_type, :klass_id]
      t.index [:schema_id, :klass_id]
    end

    create_table :dynamic_cascade_levels, id: :uuid do |t|
      t.belongs_to :schema, type: :uuid
      t.belongs_to :cascade, type: :uuid

      t.integer :depth, :default => 0
      t.datetime :updated_at
      t.datetime :deleted_at, index: true
    end

    create_table :dynamic_cascade_elements, id: :uuid do |t|
      t.belongs_to :schema, type: :uuid
      t.belongs_to :cascade, type: :uuid
      t.belongs_to :level, type: :uuid

      t.text :method_name, default: nil
      t.belongs_to :object, polymorphic: true, type: :uuid

      t.datetime :updated_at
      t.datetime :deleted_at, index: true
    end
  end

end
