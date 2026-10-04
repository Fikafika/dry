class AddCollationToDynamicRecordAttributeString < ActiveRecord::Migration[6.0]
  def change
    Dynamic::Schema::Klass.find_each do |k|
      max_string_col = k.max_not_indexed_column(Dynamic::Schema::Attribute::String)
      for i in 0..(max_string_col - 1) do
        change_column k.const_table_name.to_sym, :"s#{i}", :string, collation: 'case_insensitive'
      end
      max_indexed_string_col = k.max_indexed_column(Dynamic::Schema::Attribute::String)
      for i in 0..(max_indexed_string_col - 1) do
        change_column k.const_table_name.to_sym, :"si#{i}", :string, collation: 'case_insensitive'
      end

      max_string_col = k.max_not_indexed_column(Dynamic::Schema::Attribute::String)
      for i in 0..(max_string_col - 1) do
        change_column k.const_translation_table_name.to_sym, :"ts#{i}", :string, collation: 'case_insensitive'
      end
      max_indexed_string_col = k.max_indexed_column(Dynamic::Schema::Attribute::String)
      for i in 0..(max_indexed_string_col - 1) do
        change_column k.const_translation_table_name.to_sym, :"tsi#{i}", :string, collation: 'case_insensitive'
      end
    end
  end
end
