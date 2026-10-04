class CreateUneekPermissionRules < ActiveRecord::Migration[6.0]
  def change
    create_table :uneek_permission_rules, id: :uuid do |t|
      t.belongs_to :domain, index: true, type: :uuid
      t.string :klass_name, null: false, index: true
      t.belongs_to :instance, polymorphic: true, index: true, type: :uuid
      t.belongs_to :receiver, polymorphic: true, null: false, index: true, type: :uuid
      t.string :attr, index: true
      t.integer :grant, null: false, index: true
      t.index [:klass_name, :receiver_id, :receiver_type], unique: true, name: :uneek_permission_klass_uq, where: "(domain_id IS NULL AND instance_id IS NULL AND instance_type IS NULL AND attr IS NULL)"
      t.index [:klass_name, :receiver_id, :receiver_type, :domain_id], unique: true, name: :uneek_permission_klass_domain_uq, where: "(domain_id IS NOT NULL AND instance_id IS NULL AND instance_type IS NULL AND attr IS NULL)"
      t.index [:klass_name, :receiver_id, :receiver_type, :attr], unique: true, name: :uneek_permission_klass_attr_uq, where: "(domain_id IS NULL AND instance_id IS NULL AND instance_type IS NULL AND attr IS NOT NULL)"
      t.index [:klass_name, :receiver_id, :receiver_type, :attr, :domain_id], unique: true, name: :uneek_permission_klass_attr_domain_uq, where: "(domain_id IS NOT NULL AND instance_id IS NULL AND instance_type IS NULL AND attr IS NOT NULL)"
      t.index [:klass_name, :instance_id, :instance_type, :receiver_id, :receiver_type], unique: true, name: :uneek_permission_klass_instance_uq, where: "(domain_id IS NULL AND attr IS NULL AND instance_id IS NOT NULL AND instance_type IS NOT NULL)"
      t.index [:klass_name, :instance_id, :instance_type, :receiver_id, :receiver_type, :domain_id], unique: true, name: :uneek_permission_klass_instance_domain_uq, where: "(domain_id IS NOT NULL AND attr IS NULL AND instance_id IS NOT NULL AND instance_type IS NOT NULL)"
      t.index [:klass_name, :instance_id, :instance_type, :receiver_id, :receiver_type, :attr], unique: true, name: :uneek_permission_uq, where: "(domain_id IS NULL AND attr IS NOT NULL AND instance_id IS NOT NULL AND instance_type IS NOT NULL)"
      t.index [:klass_name, :instance_id, :instance_type, :receiver_id, :receiver_type, :attr, :domain_id], unique: true, name: :uneek_permission_domain_uq, where: "(domain_id IS NOT NULL AND attr IS NOT NULL AND instance_id IS NOT NULL AND instance_type IS NOT NULL)"
    end
  end
end
