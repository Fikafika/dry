class AddNullFalseToPermalinkOfDynamicSchema < ActiveRecord::Migration[6.0]
  def change
    change_column_null :dynamic_schemas, :permalink, false
  end
end