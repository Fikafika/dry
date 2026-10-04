module LoadSchema; extend ActiveSupport::Concern

  def load_schema
    Dynamic::Schema.load(schema_name) do |schema|
      @schema = schema
      yield
      schema
    end || (raise ActiveRecord::RecordNotFound)
  end

  def schema_name
    raise 'not implemented'
  end

end