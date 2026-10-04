class AddWhereConditionInIndexTemplateIdPosition < ActiveRecord::Migration[6.0]
  def change
    ActiveRecord::Base.connection.tables.each do |t|
      next unless t.start_with?('d_') && t.end_with?('_r_doc_gen_merge_files')
      short_table_name = t.split('_').map{|c| c[0]}.join
      salt = (rand * (10 ** 6)).to_i
      short_name = "idx_#{short_table_name}_template_id_and_position"[0..57]

      remove_index t, [:template_id, :position]
      add_index t, [:template_id, :position], unique: true, name: "#{short_name}_#{salt}", where: '(deleted_at IS NULL)'
    end
  end
end
