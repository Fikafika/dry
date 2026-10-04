# frozen_string_literal: true

class RemoveNilSerializedDefaultValueFromFormElements < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Form::Element::Base.where(default_value: "{\"$$id\"=>4, \"$$frozen\"=>true, \"$$comparable\"=>false}").find_each do |e|
      e.update!(default_value: nil)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
