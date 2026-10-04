class UpdateThemes11 < ActiveRecord::Migration[8.0]
  def change
    Dynamic::Theme.touch_all
  end
end
