# frozen_string_literal: true

class CreateDefaultLayoutsForTables < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      schema.klasses.find_each do |klass|
        next if Dynamic::Layout.with_action('index').where(default: true, klass_name: klass.const_absolute_name).exists?
        klass.create_default_layout_index
      end
    end
  end

  def down
  end
end
