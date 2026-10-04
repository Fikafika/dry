# frozen_string_literal: true

class MoveAttributeNameToAttributePath < ActiveRecord::Migration[6.0]
  def up
    Dynamic::Schema.find_each do |s|
      s.load
      k = "D::#{s.name}::R::DocGen::Merge::AttributeFile".safe_constantize
      next unless k
      k.find_each do |file|
        next unless file.attribute_path.blank? && file.respond_to?(:attribute_name) && file.attribute_name.present?
        file.update!(attribute_path: [file.attribute_name])
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
