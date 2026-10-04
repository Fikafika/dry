# frozen_string_literal: true

class DataReplaceProtocolsEnumToBitfield < ActiveRecord::Migration[6.0]
  def up
    Dynamic::Schema::Attribute::Base.reset_column_information
    scope = Dynamic::Schema::Attribute::Base.where.not(protocols: nil)
    bar = ProgressBar.new(scope.count)

    scope.find_each do |a|
      a.protocols = 1 << a.read_attribute(:protocols)
      a.save!
      bar.increment!
    end
  end

  def down
  end
end
