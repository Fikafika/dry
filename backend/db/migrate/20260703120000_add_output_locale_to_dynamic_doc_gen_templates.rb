class AddOutputLocaleToDynamicDocGenTemplates < ActiveRecord::Migration[6.0]
  include ::Dynamic::Mount::Migration

  def change
    change_tables(::Dynamic::DocGen::Template) do |t|
      t.string :output_locale, if_not_exists: true
    end
  end
end
