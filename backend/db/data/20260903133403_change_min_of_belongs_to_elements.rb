# frozen_string_literal: true

class ChangeMinOfBelongsToElements < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Form::Element::Association::BelongsTo.where(mode: 'nested_form', min: nil).update_all(min: 1)
  end

  def down
  end
end
