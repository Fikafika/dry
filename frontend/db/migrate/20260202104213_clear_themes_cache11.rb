class ClearThemesCache11 < ActiveRecord::Migration[7.0]
  def change
    FileUtils.rm(Dir['public/themes/**/*.css'])
  end
end
