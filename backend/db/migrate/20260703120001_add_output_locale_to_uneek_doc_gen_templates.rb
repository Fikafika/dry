class AddOutputLocaleToUneekDocGenTemplates < ActiveRecord::Migration[6.0]
  def change
    add_column :uneek_doc_gen_templates, :output_locale, :string, if_not_exists: true
  end
end
