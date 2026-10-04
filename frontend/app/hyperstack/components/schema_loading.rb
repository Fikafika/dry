require 'active_support/concern'

module SchemaLoading; extend ActiveSupport::Concern

  def schema
    Dynamic::Schema.load(schema_name) { mutate }
  end

  def schema_name
    request.params[:schema] || request.params[:schema_id]
  end

end

