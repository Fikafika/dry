class AddColumnAttributePathToDocGenMergeFiles < ActiveRecord::Migration[6.0]
  def change
    ActiveRecord::Base.connection.tables.each do |t|
      next unless t.start_with?('d_') && t.end_with?('_r_doc_gen_merge_files')
      add_column t, :attribute_path, :text, default: [].to_yaml, if_not_exists: true
    end
  end
end
