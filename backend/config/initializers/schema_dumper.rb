ActiveSupport.on_load(:active_record) do
  ActiveRecord::SchemaDumper.ignore_tables << /\Ahyperstack_/
end
