ActiveSupport.on_load(:dynamic_schema_attribute_string) do

  safe_enum :editor, {
    text: 1, # default
    autocomplete: 5,
  }

end
