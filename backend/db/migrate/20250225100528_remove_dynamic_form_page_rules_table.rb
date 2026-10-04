class RemoveDynamicFormPageRulesTable < ActiveRecord::Migration[8.0]
  def change
    drop_table :dynamic_form_page_rules
  end
end
