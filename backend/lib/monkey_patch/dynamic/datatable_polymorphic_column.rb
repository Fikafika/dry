# frozen_string_literal: true

ActiveSupport.on_load(:dynamic_datatable_elasticsearch) do
  module DatatablePolymorphicColumn
    def col_reflection(col_name, raise_if_missing: false)
      r = @klass
      result = nil
      splitted_path = col_name.split('.')
      splitted_path.each_with_index do |e, i|
        reflection = r&.reflect_on_association(e)
        reflection = nil if reflection && reflection.options[:polymorphic]
        r = reflection&.klass
        result = reflection if i == splitted_path.length - 1
      end
      return result
    end
  end

  Dynamic::Datatable::Elasticsearch.prepend(DatatablePolymorphicColumn)
end
