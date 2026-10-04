# frozen_string_literal: true

class AddDefaultValueForRecordTypeForDefaultValueFormulaToDynamicFormElement < ActiveRecord::Migration[6.0]
  def up
    Dynamic::Form::Element::Base.where.not(default_value_formula: nil).find_each do |e|
      e.update!(record_type_for_default_value_formula: :root_record)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
