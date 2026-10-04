# frozen_string_literal: true

class CreateDefaultLayoutForFormThumbnail < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      schema.klasses.find_each do |klass|
        next if Dynamic::Layout.with_action('show').where(default: true, klass_name: klass.const_absolute_name, purpose: 'thumbnail').exists?
        klass.create_default_layout_show_thumbnail
      end
    end
  end

  def down
    Dynamic::Layout.with_action('show').where(default: true, purpose: 'thumbnail').destroy_all
  end
end
