# frozen_string_literal: true

class UpdateFormElementAssociations < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema::Association::Base.find_each do |a|
      target_type = a.type == 'HasMany' ? 'BelongsTo' : 'HasMany'
      Dynamic::Form::Element::Association.const_get(target_type).where(
        klass_name: a.owner_klass.const_absolute_name,
        attribute_name: a.name
      ).find_each do |elem|
        elem.update!(type: "Association::#{a.type}")
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
