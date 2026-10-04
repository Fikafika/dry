class CorrectCssClassesTab < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Form::Element::Base.where('CAST(css_classes AS text) LIKE \'[%\' ').update_all(css_classes: nil)
  end
  def down
  end
end