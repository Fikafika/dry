class AddPermalinkToDynamicSchema < ActiveRecord::Migration[6.0]
  def change
    change_table :dynamic_schemas do |t|
      t.string :permalink
    end
  end
end
