class AddThemeToForms < ActiveRecord::Migration[6.0]
  def change
    add_reference :dynamic_forms, :theme, type: :uuid
  end
end
