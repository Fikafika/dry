class AddDependentDestroyAndTouchTargetToDynamicSchemaAssociations < ActiveRecord::Migration[6.0]
  def change
    change_table :dynamic_schema_associations do |t|
      t.boolean :dependent_destroy, default: false
      t.boolean :touch_target, default: false
    end
  end
end
