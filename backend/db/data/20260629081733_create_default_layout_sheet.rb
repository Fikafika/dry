# frozen_string_literal: true

class CreateDefaultLayoutSheet < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      schema.klasses.find_each do |klass|
        layouts = Dynamic::Layout.with_action('show').where(default: true, klass_name: klass.const_absolute_name, purpose: nil)
        if layouts.exists?
          layouts.find_each do |layout|
            layout.update!(
              purpose: 'sheet',
              human_name_en: 'List item for sheet',
              human_name_fr: 'Vignette pour les fiches'
            )
          end
        else
          klass.create_default_layout_show_sheet
        end
      end
    end
  end

  def down
    Dynamic::Layout.with_action('show').where(default: true, purpose: 'sheet').destroy_all
  end
end
