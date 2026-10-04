class CreateUneekPermissionDomains < ActiveRecord::Migration[6.0]
  def change
    create_table :uneek_permission_domains, id: :uuid do |t|
      t.string :expression_method
      t.string :expression_value
      t.integer :expression_value_type
      t.string :user_field
      t.string :instance_field, null: false
      t.string :context_field
      t.index [:instance_field, :context_field], unique: true, name: :uneek_permission_domains_uq, where: "expression_method IS NULL AND expression_value IS NULL AND user_field IS NULL"
      t.index [:instance_field, :user_field], unique: true, name: :uneek_permission_domains_user_uq
      t.index [:instance_field, :expression_method, :expression_value], unique: true, name: :uneek_permission_domains_expresion_uq
    end
  end
end
