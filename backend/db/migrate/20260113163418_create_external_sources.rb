class CreateExternalSources < ActiveRecord::Migration[8.0]
  def change
    create_table :external_sources, id: :uuid do |t|
      t.text :url
      t.timestamps
    end
    create_table :external_source_translations, id: :uuid do |t|
      t.belongs_to :external_source, type: :uuid
      t.string :human_name
      t.string :locale
      t.timestamps
    end
  end
end
