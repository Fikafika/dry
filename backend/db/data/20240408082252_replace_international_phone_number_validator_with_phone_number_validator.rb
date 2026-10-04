# frozen_string_literal: true

class ReplaceInternationalPhoneNumberValidatorWithPhoneNumberValidator < ActiveRecord::Migration[6.0]
  def up
    Dynamic::Schema::Feature.transaction do
      Dynamic::Schema::Validation::Base.where(type: 'Dynamic::Schema::Validation::Format::InternationalPhoneNumber').update_all(type: 'Dynamic::Schema::Validation::Format::PhoneNumber')
    end
  end

  def down
    #raise ActiveRecord::IrreversibleMigration
  end
end
