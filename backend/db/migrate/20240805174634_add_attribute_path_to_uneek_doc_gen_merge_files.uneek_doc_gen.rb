# This migration comes from uneek_doc_gen (originally 20240730145527)
class AddAttributePathToUneekDocGenMergeFiles < ActiveRecord::Migration[6.0]
  def change
    add_column :uneek_doc_gen_merge_files, :attribute_path, :text, default: [].to_yaml
  end
end
