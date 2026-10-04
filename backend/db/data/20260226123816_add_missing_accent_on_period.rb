# frozen_string_literal: true

class AddMissingAccentOnPeriod < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema::Feature.where(name: 'Dynamic::Period::Feature').find_each do |f|
      f.update(human_name_fr: 'Période')
    end
  end

  def down
  end
end
