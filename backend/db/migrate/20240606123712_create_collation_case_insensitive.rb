class CreateCollationCaseInsensitive < ActiveRecord::Migration[6.0]
  def change
    create_collation :case_insensitive
  end
end
