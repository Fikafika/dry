class AddDeletedAtToDynamicFormTranslations < ActiveRecord::Migration[6.0]
  def change
    change_table :dynamic_form_translations do |t|
      t.datetime :deleted_at, index: true
    end

    change_table :dynamic_form_element_translations do |t|
      t.datetime :deleted_at, index: true
    end

    change_table :dynamic_form_element_possible_value_translations do |t|
      t.datetime :deleted_at, index: {name: 'index_d_form_element_possible_value_translations_on_deleted_at'}
    end
  end
end
