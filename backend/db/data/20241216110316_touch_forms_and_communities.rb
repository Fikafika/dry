# frozen_string_literal: true

class TouchFormsAndCommunities < ActiveRecord::Migration[6.0]
  def up
    # touch form and communities in order to invalidate theme caches
    Dynamic::Form.touch_all
    Community.touch_all
  end

  def down
  end
end
