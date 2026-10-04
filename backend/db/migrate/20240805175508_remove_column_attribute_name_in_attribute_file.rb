class RemoveColumnAttributeNameInAttributeFile < ActiveRecord::Migration[6.0]
  def change
    ActiveRecord::Base.connection.tables.each do |t|
      next unless t.start_with?('d_') && t.end_with?('_r_doc_gen_merge_files')
      remove_column t, :attribute_name, if_exists: true
    end
    remove_column :uneek_doc_gen_merge_files, :attribute_name, if_exists: true
  end
end
