class AddDynamicSchemaToCommunities < ActiveRecord::Migration[6.0]
  def change
    change_table :communities do |t|
      t.references :schema, foreign_key: {to_table: :dynamic_schemas}, null: false, type: :uuid
    end
  end
end
