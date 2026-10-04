# frozen_string_literal: true

class CreateDefaultFormSheet < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Schema.find_each do |schema|
      schema.klasses.find_each do |klass|
        forms = Dynamic::Form.with_action('show').where(default: true, klass_name: klass.const_absolute_name, purpose: nil)
        if forms.exists?
          forms.find_each do |form|
            form.update!(
              purpose: 'sheet',
              human_name_en: 'List item for sheet',
              human_name_fr: 'Vignette pour les fiches'
            )
          end
        else
          klass.create_default_form_show_sheet
        end
      end
    end
  end

  def down
    Dynamic::Form.with_action('show').where(default: true, purpose: 'sheet').destroy_all
  end
end
