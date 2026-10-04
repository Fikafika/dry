# frozen_string_literal: true

class DataAddPathToImportColumns < ActiveRecord::Migration[6.0]
  def up
    bar = ProgressBar.new(Dynamic::Import::Column.count)

    Dynamic::Import::Column.find_each do |c|
      c.save(touch: false) if c.path.empty?
      bar.increment!
    end
  end

  def down
  end
end
