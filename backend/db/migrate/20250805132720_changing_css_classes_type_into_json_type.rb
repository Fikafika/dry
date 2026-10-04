class ChangingCssClassesTypeIntoJsonType < ActiveRecord::Migration[8.0]
  def change

    Dynamic::Form::Element::Base.update_all(css_classes: nil)

    change_column :dynamic_form_elements, :css_classes, 'json USING CAST(css_classes AS json)'

  end
end
