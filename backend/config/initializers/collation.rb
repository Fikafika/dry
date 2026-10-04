ActiveSupport.on_load(:dynamic_schema_attribute_string) do
  def self.postgresql_collation
    {collation: 'case_insensitive'}
  end
end