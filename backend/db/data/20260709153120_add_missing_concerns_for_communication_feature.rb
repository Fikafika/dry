# frozen_string_literal: true

class AddMissingConcernsForCommunicationFeature < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |s|
      s.features.where(name: 'Dynamic::Communication::Feature').find_each do |f|
        Dynamic::Communication::Feature.feature_attributes[:concerns_attributes].each do |h|
          next if f.concerns.detect{|c| c.name == h[:name]}
          f.concerns.create!(h)
        end
      end
    end
  end

  def down
  end
end