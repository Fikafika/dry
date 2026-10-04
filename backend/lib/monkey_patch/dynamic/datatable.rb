# frozen_string_literal: true

ActiveSupport.on_load(:dynamic_datatable_elasticsearch) do
  module DatatablePermissions
    def filter_records(records)
      schema_name = @klass.module_parent_name&.split('::')&.last
      return super unless @klass.include?(::Dynamic::Permission::OpenSearch::ControlledKlass) && !User.current&.admin?(schema_name)
      records.search_as(User.current, elasticsearch_query)
    end
  end

  Dynamic::Datatable::Elasticsearch.prepend(DatatablePermissions)
end
